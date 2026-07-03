# BudgetBoss 💰

BudgetBoss is a personal finance tracker built for the Ghanaian market.
It reads MoMo SMS notifications directly from your Android device,
automatically parses transaction details, and gives you a clear picture
of where your money goes.

## Features

- 📲 Auto-parses MTN MoMo and Telecel Cash SMS notifications
- 🗂️ Auto-categorizes transactions (Airtime, Food, Transport, Utilities, etc.)
- 📊 Dashboard with spending breakdown pie chart
- 💳 Budget tracking with over-budget alerts
- 🎯 Savings goals with progress tracking
- 🔔 Real-time push notifications when budgets are exceeded
- ☁️ Cloud sync via Supabase with per-user data isolation

## Stack

- **Frontend:** Flutter (Android)
- **Database:** Supabase (PostgreSQL)
- **Auth:** Supabase Auth
- **Notifications:** flutter_local_notifications

## Supported Networks

- MTN MoMo ✅
- Telecel Cash (formerly Vodafone Cash) ✅
- AirtelTigo Money (in progress)

## Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/eugene234466/BudgetBoss.git
cd BudgetBoss
```

### 2. Set up Supabase

- Create a free project at [supabase.com](https://supabase.com)
- Go to the SQL Editor and run the schema in step 4 below
- Go to Project Settings → API and copy your Project URL and anon key

### 3. Configure app constants

Open `lib/core/constants/app_constants.dart` and replace the placeholders with your own Supabase credentials:

```dart
static const String supabaseUrl = 'YOUR_PROJECT_URL';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### 4. Run the database schema

In your Supabase SQL Editor, run:

```sql
create extension if not exists "uuid-ossp";

create table transactions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  amount numeric(12, 2) not null,
  type text check (type in ('debit', 'credit')) not null,
  sender_or_recipient text,
  category text not null default 'Other',
  raw_sms text not null,
  timestamp timestamptz not null,
  created_at timestamptz default now()
);

create table budgets (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  category text not null default 'overall',
  limit_amount numeric(12, 2) not null,
  period text check (period in ('monthly', 'weekly')) not null default 'monthly',
  created_at timestamptz default now(),
  unique (user_id, category)
);

create table goals (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  target_amount numeric(12, 2) not null,
  current_amount numeric(12, 2) not null default 0,
  monthly_contribution numeric(12, 2),
  deadline date,
  created_at timestamptz default now()
);

alter table transactions enable row level security;
alter table budgets enable row level security;
alter table goals enable row level security;

create policy "Users can view own transactions"
  on transactions for select using (auth.uid() = user_id);
create policy "Users can insert own transactions"
  on transactions for insert with check (auth.uid() = user_id);
create policy "Users can delete own transactions"
  on transactions for delete using (auth.uid() = user_id);

create policy "Users can view own budgets"
  on budgets for select using (auth.uid() = user_id);
create policy "Users can insert own budgets"
  on budgets for insert with check (auth.uid() = user_id);
create policy "Users can update own budgets"
  on budgets for update using (auth.uid() = user_id);
create policy "Users can delete own budgets"
  on budgets for delete using (auth.uid() = user_id);

create policy "Users can view own goals"
  on goals for select using (auth.uid() = user_id);
create policy "Users can insert own goals"
  on goals for insert with check (auth.uid() = user_id);
create policy "Users can update own goals"
  on goals for update using (auth.uid() = user_id);
create policy "Users can delete own goals"
  on goals for delete using (auth.uid() = user_id);

alter table transactions
  add constraint unique_user_sms unique (user_id, raw_sms);
```

### 5. Install dependencies and run

```bash
flutter pub get
flutter run
```

## Permissions Required

- **READ_SMS** — to read MoMo SMS from inbox
- **POST_NOTIFICATIONS** — to send budget alert notifications

## Course

ENCE216-13 · FinTech · GCTU
Group A · BudgetBoss · Team 4 (GA-T13-N04)
