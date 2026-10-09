// Generate SQL to import all 50 fictional catalog medicines via Supabase SQL Editor.
import {writeFileSync} from 'node:fs';
import {catalog} from '../src/catalog.js';
const esc=x=>x==null?'NULL':`'${String(x).replaceAll("'","''")}'`;
const columns=['id','name','category','strength','price','stock','type','manufacturer','expiry','reorder_level','notes'];
let sql='-- Educational sample prices, stock and dates. Not real clinical data.\ninsert into public.medicines ('+columns.join(',')+') values\n';
sql+=catalog.map(m=>'('+columns.map(k=>['price','stock','reorder_level'].includes(k)?Number(m[k]):esc(m[k])).join(',')+')').join(',\n');
sql+='\non conflict (id) do nothing;\n';
writeFileSync(new URL('./seed.sql',import.meta.url),sql);
console.log(`Wrote ${catalog.length} medicines to supabase/seed.sql`);
