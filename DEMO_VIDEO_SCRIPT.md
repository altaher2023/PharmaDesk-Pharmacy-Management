# PharmaDesk Demo Video — 4-minute Recording Guide

**Record this yourself on the actual deployed Netlify URL, not localhost.** Suggested title: "ED2 — PharmaDesk | AI-Assisted Pharmacy Management Prototype".

**00:00–00:30 — Introduction:** "This is PharmaDesk, a simple educational pharmacy management web app built with React and Supabase. It has separate administrator and pharmacist accounts, inventory management, mock prescription checkout, and printable receipts."

**00:30–01:00 — Sign in:** Show the registered administrator and pharmacist credentials working. Never display or share actual passwords in your video; use disposable demonstration accounts. Explain that public signup defaults to pharmacist permissions.

**01:00–01:50 — Administrator:** Show medicine inventory with the 50 preloaded sample items. Search by name, update one sample medicine's unit price, stock, manufacturer, or expiration date, and save it. Show the low-stock dashboard alerts.

**01:50–02:50 — Pharmacist:** Sign out and sign in as pharmacist. Demonstrate that medicine editing controls are not available. Add an OTC and an Rx medicine to a cart, enter a fake customer label and fake prescription reference, check out, and print the example receipt.

**02:50–03:30 — Database:** Open the Supabase Table Editor (with private credentials and real data hidden). Show the medicines stock decreased and the new record in sales and sale_items.

**03:30–04:10 — Code + GitHub:** Show the public GitHub repository. Point to src/main.jsx (UI and workflows), src/supabase.js (client config), src/catalog.js (demo list), supabase/schema.sql (tables, role policies, checkout transaction), and README.md. Briefly show meaningful commit history made as you developed/customized the project.

**04:10–04:30 — Wrap-up:** Explain that the app is an educational proof of concept only and doesn't provide clinical, regulatory, or real patient-data capabilities. Upload to YouTube as *Unlisted* and add the link to README.
