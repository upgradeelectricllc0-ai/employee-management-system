# EMS — Employee Management System

A white-labeled, single-tenant B2B SaaS web application for managing employees, tracking attendance, scheduling shifts, and handling leave requests.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Next.js 15 (App Router) |
| Language | TypeScript |
| Styling | Tailwind CSS + shadcn/ui |
| Database | PostgreSQL via Supabase |
| Auth | Supabase Auth (JWT + RLS) |
| Storage | Supabase Storage |
| PDF Export | @react-pdf/renderer |
| Deployment | Vercel |
| Validation | Zod + React Hook Form |
| Date/Time | date-fns |

## Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/upgradeelectricllc0-ai/employee-management-system
cd employee-management-system
```

### 2. Install dependencies
```bash
npm install
```

### 3. Set up environment variables
```bash
cp .env.example .env.local
```
Fill in your Supabase project URL, anon key, and service role key.

### 4. Run database migrations
Apply migration files in `supabase/migrations/` in order via the Supabase dashboard SQL editor or Supabase CLI.

### 5. Start development server
```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) and complete the one-time setup wizard.

## Project Structure

```
├── app/
│   ├── (public)/          # Login, setup wizard, password reset
│   ├── (admin)/           # All admin routes (protected)
│   ├── (employee)/        # All employee routes (protected)
│   └── api/               # REST API routes (exports, webhooks)
├── components/
│   ├── ui/                # shadcn/ui primitives
│   ├── layout/            # Sidebar, TopBar, PageHeader
│   ├── employees/
│   ├── attendance/
│   ├── schedules/
│   ├── leave/
│   └── reports/
├── lib/
│   ├── supabase/          # Supabase client (browser, server, middleware)
│   ├── actions/           # Next.js Server Actions
│   └── utils/             # Helpers (timeCalculations, pdfGenerator)
└── supabase/
    └── migrations/        # Ordered SQL migration files
```

## Roles

- **Admin** — Full access: manage employees, approve leave, create schedules, view reports
- **Employee** — Limited access: clock in/out, view schedule, submit leave requests, update own profile

## Deployment

Deploy to Vercel with one click. Set the environment variables in your Vercel project dashboard.

## License

Private — all rights reserved.
