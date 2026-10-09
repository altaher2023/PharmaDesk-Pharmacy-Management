# PharmaDesk — ED2 Pharmacy Management System

**An educational sample web app** with secure role-based accounts, a 50-medicine sample catalog, inventory management, mock prescription checkout, transaction history and printable receipts. **Do not use this app for actual dispensing, prescriptions, real patient records, clinical decisions, payments or protected health information.** Medicine details, pricing, stock, and dates are fictional demonstration values.

## Live app / demo video / GitHub

- **Live app:** https://pharmadesk-system.netlify.app/
- **3–5 minute video:** _Add your unlisted YouTube link here after recording._
- **Repository:** https://github.com/altaher2023/PharmaDesk-Pharmacy-Management

## Features and permissions

| Feature | Administrator | Pharmacist |
|---|---|---|
| Register, login, logout | Yes | Yes |
| View/search medicine catalog | Yes | Yes |
| Create/edit/delete medicine details, price, stock, expiry, and reorder level | Yes | No |
| Create sales and reduce stock atomically | Yes | Yes |
| View transaction history, view/print receipts | Yes | Yes |

New signups receive the **pharmacist** role. Administrators must be promoted by a trusted project owner in Supabase SQL Editor, not from the browser. RLS and server-side checkout enforcement protect the roles, and medicine stock/receipt writes occur inside one transaction. Do not put a service-role key in the frontend.

## Stack

- React + Vite frontend, Lucide icons
- Supabase Auth, Postgres, RLS and PL/pgSQL checkout RPC
- Netlify static deployment
- Git/GitHub source control

## Local setup

1. Install Node.js 20+ and run `npm install`.
2. Create a free **Supabase** project. Open its **SQL Editor** and run `supabase/schema.sql`.
3. Run `supabase/seed.sql` in SQL Editor to add 50 example medicines. The SQL seed is already included. 
4. In Supabase **Authentication → Providers**, enable email login; for a classroom demonstration you can choose appropriate email-confirmation settings. In **Authentication → URL Configuration**, configure your Netlify site URL and localhost redirect URLs as appropriate.
5. Sign up a first user in the running app. To promote that user to admin, execute this query in Supabase SQL Editor **with your own email** (do not run it from the web client):

```sql
update public.profiles set role='admin'
where id = (select id from auth.users where email='YOUR_ADMIN_EMAIL');
```

6. Copy `.env.example` to `.env` and provide the **Supabase project URL** and **publishable/anon key** (never the service_role secret). `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` are browser-visible, so access is enforced with RLS.
7. Run `npm run dev` and open the URL Vite prints.
8. Sign in. If you changed a user's role while logged in, log out and sign in again to refresh the profile.

**No backend configured?** The landing page has **Admin demo** and **Pharmacist demo** buttons. They run with fictional in-memory data. Demo-mode modifications disappear on reload and are **not** Supabase/GitHub persistence.

## Deploy with Netlify

1. Push the project to a **public GitHub repository**. Do not commit `.env` (already gitignored).
2. At Netlify, import the GitHub repo. Build command: `npm run build`; publish directory: `dist`.
3. In **Site configuration → Environment variables**, set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
4. Deploy. Update Supabase Auth **Site URL** and **Redirect URLs** with the deployed URL; test registration, login and checkout on the deployed site.
5. Add the live URL and unlisted video link to the top of this README.

> **Important:** a ZIP created locally cannot independently create a GitHub repository, Netlify site, Supabase project or YouTube video. These require owner account actions.

## Recommended Git history

The assignment asks you to **make real commits progressively**. Do not fabricate a commit history. Example milestones while you review/customize this sample: `Initialize Vite UI`, `Set up Supabase schema and RLS`, `Add medicine management`, `Add checkout and receipts`, `Document and test deployment`.

## Database model

- `profiles`: Supabase-authenticated user, display name and `admin` / `pharmacist` role
- `medicines`: SKU, medicine, category, strength, Rx/OTC, unit price, units, manufacturer, expiry, reorder threshold, notes
- `sales`: receipt number, user, reference identifiers, totals, date/time
- `sale_items`: quantity and unit-price snapshot per transaction

`checkout` rejects empty/duplicate carts, insufficient or expired stock and missing prescription references for Rx medicines. It **does not verify prescriptions**, allergies, interactions, dosage, identity, insurance or legal eligibility. Tax is deliberately fixed at 0 for demonstration, not jurisdiction-specific tax calculation.

## 3–5 minute demo script

- **0:00–0:30** — Show the *deployed Netlify link* and introduce PharmaDesk.
- **0:30–1:00** — Register/login with Supabase test accounts; explain the two roles. (Prepare the admin account beforehand.)
- **1:00–1:50** — As admin, search the 50 medicines, add/edit one, show stock and expiry fields.
- **1:50–2:50** — As pharmacist, demonstrate catalog access, lack of admin controls, add medicines to a sale, enter a fictional prescription reference, complete checkout and print the receipt.
- **2:50–3:30** — Show Supabase `medicines`, `sales` and `sale_items` with the newly created data and stock reduced.
- **3:30–4:20** — Open the GitHub repository; explain `src/main.jsx`, `src/catalog.js`, `supabase/schema.sql`, and deployment settings.
- **4:20–4:40** — Explain RLS/role security and remind viewers this is an educational prototype.

Record a genuine screen capture of the **deployed website**, upload as **Unlisted** to YouTube and include its URL in this README. Do not claim demo mode is database-backed.

## Validation checklist

- [ ] Run `npm run build`
- [ ] Connect Supabase and import 50 medicine rows
- [ ] Register administrator and pharmacist; promote only the trusted administrator
- [ ] Confirm pharmacist cannot insert/update/delete `medicines` through backend API
- [ ] Confirm expired/out-of-stock items cannot be sold
- [ ] Confirm Rx reference is required for Rx checkout
- [ ] Verify stock decreases and sales + sale items appear together
- [ ] Print sample receipt
- [ ] Verify live deployment and GitHub/YouTube links

## Privacy and scope

This assignment project uses **dummy patient references** only. Real pharmacy software needs professional regulatory review, controlled access, audit logs, prescription verification, encryption and confidentiality controls, compliant retention, clinical checks and jurisdiction-specific requirements. This sample is **not** production pharmacy software.
