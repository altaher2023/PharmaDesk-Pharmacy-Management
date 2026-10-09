-- Run in Supabase SQL editor. Sample educational app; not for real patient information.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default '',
 role text not null default 'pharmacist' check (role in ('admin','pharmacist')),
 created_at timestamptz not null default now()
);
create table if not exists public.medicines (
 id text primary key,
 name text not null,
 category text not null default 'Other',
 strength text not null default '',
 price numeric(10,2) not null check(price>=0),
 stock integer not null default 0 check(stock>=0),
 type text not null default 'Rx' check(type in ('Rx','OTC')),
 manufacturer text not null default '',
 expiry date,
 reorder_level integer not null default 20 check(reorder_level>=0),
 notes text not null default '',
 updated_at timestamptz not null default now()
);
create table if not exists public.sales (
 id uuid primary key default gen_random_uuid(),
 receipt_no bigint generated always as identity unique,
 pharmacist_id uuid not null references auth.users(id),
 customer_label text not null default 'Walk-in customer',
 prescription_ref text not null default '',
 subtotal numeric(10,2) not null,
 tax numeric(10,2) not null default 0,
 total numeric(10,2) not null,
 created_at timestamptz not null default now()
);
create table if not exists public.sale_items (
 id bigint generated always as identity primary key,
 sale_id uuid not null references public.sales(id) on delete cascade,
 medicine_id text not null references public.medicines(id),
 medicine_name text not null,
 strength text not null,
 quantity integer not null check(quantity>0),
 unit_price numeric(10,2) not null,
 line_total numeric(10,2) not null
);
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$
 select exists (select 1 from public.profiles where id=auth.uid() and role='admin');
$$;
create or replace function public.is_staff() returns boolean language sql stable security definer set search_path=public as $$
 select exists (select 1 from public.profiles where id=auth.uid());
$$;
-- Never let new registrants choose their own admin role.
create or replace function public.create_profile() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,display_name,role) values (new.id,coalesce(new.raw_user_meta_data->>'display_name',''), 'pharmacist');
 return new;
end;$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.create_profile();
-- Backfill existing auth users if running schema on an established project.
insert into public.profiles(id,display_name,role)
 select id,coalesce(raw_user_meta_data->>'display_name',''),'pharmacist' from auth.users
on conflict (id) do nothing;
alter table public.profiles enable row level security;
alter table public.medicines enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
create policy "staff see own or admin profiles" on public.profiles for select to authenticated using (id=auth.uid() or public.is_admin());
create policy "staff view medicines" on public.medicines for select to authenticated using (public.is_staff());
create policy "admin insert medicines" on public.medicines for insert to authenticated with check (public.is_admin());
create policy "admin update medicines" on public.medicines for update to authenticated using (public.is_admin()) with check(public.is_admin());
create policy "admin delete medicines" on public.medicines for delete to authenticated using (public.is_admin());
create policy "staff see sales" on public.sales for select to authenticated using (public.is_staff());
create policy "staff see sale items" on public.sale_items for select to authenticated using (public.is_staff());
-- Atomic checkout: server verifies stock and Rx reference, records immutable price snapshot, decreases stock.
create or replace function public.checkout(p_customer text,p_prescription text,p_items jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_sale uuid; v_subtotal numeric(10,2):=0; v_m public.medicines%rowtype;
 v_item jsonb; v_qty integer; v_id text; v_ids text[]; v_count integer;
begin
 if not public.is_staff() then raise exception 'Not authorized'; end if;
 if jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items)=0 then raise exception 'Cart is empty'; end if;
 if jsonb_array_length(p_items)>40 then raise exception 'Too many items'; end if;
 select array_agg(x order by x) into v_ids from (select distinct elem->>'id' as x from jsonb_array_elements(p_items) elem) t;
 if array_length(v_ids,1)<>jsonb_array_length(p_items) then raise exception 'Duplicate medicine entries'; end if;
 -- Lock stock rows in predictable ID order to avoid deadlocks.
 perform 1 from public.medicines where id=any(v_ids) order by id for update;
 foreach v_id in array v_ids loop
  select * into strict v_m from public.medicines where id=v_id;
  select elem into v_item from jsonb_array_elements(p_items) elem where elem->>'id'=v_id;
  if jsonb_typeof(v_item->'quantity') <> 'number' or (v_item->>'quantity') !~ '^[0-9]+$' then raise exception 'Invalid quantity'; end if;
  v_qty:=(v_item->>'quantity')::integer;
  if v_qty < 1 or v_qty > 999 or v_qty>v_m.stock then raise exception 'Invalid or insufficient stock for %',v_m.name; end if;
  if v_m.expiry is not null and v_m.expiry < current_date then raise exception 'Expired medicine: %',v_m.name; end if;
  if v_m.type='Rx' and nullif(trim(coalesce(p_prescription,'')),'') is null then raise exception 'Prescription reference required for %',v_m.name; end if;
  v_subtotal:=v_subtotal+v_m.price*v_qty;
 end loop;
 insert into public.sales(pharmacist_id,customer_label,prescription_ref,subtotal,tax,total)
 values(auth.uid(),coalesce(nullif(trim(p_customer),''),'Walk-in customer'),coalesce(trim(p_prescription),''),v_subtotal,0,v_subtotal)
 returning id into v_sale;
 foreach v_id in array v_ids loop
  select * into v_m from public.medicines where id=v_id;
  select elem into v_item from jsonb_array_elements(p_items) elem where elem->>'id'=v_id;
  v_qty:=(v_item->>'quantity')::integer;
  insert into public.sale_items(sale_id,medicine_id,medicine_name,strength,quantity,unit_price,line_total)
  values(v_sale,v_m.id,v_m.name,v_m.strength,v_qty,v_m.price,v_m.price*v_qty);
  update public.medicines set stock=stock-v_qty,updated_at=now() where id=v_id;
 end loop;
 return v_sale;
end;$$;
revoke all on function public.checkout(text,text,jsonb) from public;
grant execute on function public.checkout(text,text,jsonb) to authenticated;
-- After signup, promote ONE trusted account manually in SQL editor:
-- update public.profiles set role='admin' where id=(select id from auth.users where email='YOUR_ADMIN_EMAIL');
