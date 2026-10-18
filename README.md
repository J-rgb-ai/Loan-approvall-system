# ClearPath Loan Application Portal

A human-reviewed loan application workflow with applicant sign-in, submission, status tracking, and a reviewer queue.

## Stack
- Static HTML/CSS/JavaScript
- Supabase Auth + PostgreSQL with row-level security
- Vercel hosting

## Features
- Email/password applicant accounts
- Persisted loan applications with validation for requested amount, income, purpose, employment status, and repayment term
- Applicant dashboard with current status and application event history
- Applicant withdrawal while an application is still submitted or under review
- Reviewer queue with status decisions and reviewer notes
- Row-level security separates applicants' records from the reviewer queue
- Application events record submission, withdrawal, status change, and reviewer notes

## Setup
1. Apply `supabase/migrations/20261018090000_loan_workflow.sql` to a fresh Supabase project.
2. Enable email/password authentication. In Supabase Auth → URL Configuration, set the Site URL to `https://loan-approval-system-plum.vercel.app` and add `https://loan-approval-system-plum.vercel.app/**` plus `https://loan-approval-system-whalesesys-projects.vercel.app/**` to the redirect allowlist.
3. Put the project's Supabase URL and **publishable key only** in `supabase-config.js`. Never put a service-role key in frontend files.
4. For staff review, assign reviewer role in Supabase Auth **app metadata** (never user-editable metadata). The reviewer UI checks `app_metadata.role === "reviewer"`.
5. Configure password security, privacy notice, retention policy, identity verification, and the actual lending policy before accepting real applications.

## Important
This is an application workflow, not an automated creditworthiness engine. A human reviewer must make lending decisions under a documented and compliant policy. Do not use the demo for real lending until it has been reviewed for applicable financial-services, consumer-protection, and data-protection requirements.
