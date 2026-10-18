# ClearPath Loan Application Portal

A human-reviewed loan application workflow with applicant sign-in, application submission, status tracking, and a reviewer queue.

## Stack
- Static HTML/CSS/JavaScript
- Supabase Auth and PostgreSQL with row-level security
- Vercel hosting

## Setup
1. The database schema is provisioned in Supabase project jztuppacqwmfcsigskbe.
2. Configure email/password authentication in Supabase.
3. supabase-config.js uses the project's URL and public publishable key.
4. For staff review, assign the reviewer role in Supabase Auth app metadata (never user-editable metadata). The frontend checks app_metadata.role === reviewer.

## Important
This is a workflow tool, not an automated creditworthiness engine. Configure lending policy, identity checks, privacy notices, retention, regulatory controls, and reviewer authorization before accepting real applications. The reviewer UI expects role claims to be managed by a trusted administrator.
