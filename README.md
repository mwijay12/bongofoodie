
# 🍲 Bongo Foodie - Spiced AI-Powered Swahili Gastronomy

Bongo Foodie is a next-generation mobile application that brings authentic East African Swahili cuisine directly to your fingertips, enhanced with a cutting-edge **Generative AI Chef Assistant**, custom culinary recipe generators, and a comprehensive, localized Tanzanian address system.

---

## 🚀 SECTION 1: PROJECT IDENTITY

### 🍲 Project Identity & Launch Announcement

Welcome to **Bongo Foodie**!

* **For a 10-year-old**: Bongo Foodie is like a magical food delivery app that lets you order yummy Tanzanian dishes like Chipsi Mayai and Nyama Choma, while chatting with a smart robot Chef who can make up custom recipes and generate pictures of them!
* **For a Developer**: Bongo Foodie is a highly optimized, cross-platform mobile application built on **Expo SDK 54** and **React Native**. It features a robust TypeScript codebase, utility-first styling with NativeWind (Tailwind CSS), Zustand global state management, and is powered by a high-availability **Supabase** backend with active-failover key-rotated Gemini LLM integrations for real-time conversational culinary advice, ElevenLabs for voice output, and SiliconFlow (Flux) for AI image generation.
* **The Business Problem Solved**: Traditional food delivery apps in East Africa suffer from two major friction points: **inefficient geocoding** (resulting in lost drivers and failed drop-offs due to a lack of structured physical street addresses) and **rigid menu offerings** that fail to cater to custom culinary preferences. Bongo Foodie solves the logistics challenge by implementing a normalized, highly responsive Tanzania locations database containing over **66,978** regions, districts, and wards for precise manual and GPS targeting. It addresses menu rigidity by utilizing generative AI to construct custom culinary compositions that are dynamically cost-estimated, nutrition-calculated, and converted into orderable cart items.

### Status Badge

* **Current Version**: `v1.0.0-beta.3`
* **Status**: 🟢 **Production Ready (Core Modules & DB Engine)**

### Who Built It & Why

Bongo Foodie was architected by senior mobile developers and database engineers who recognized the massive gap in localized logistics and interactive customer engagement in East Africa. The app was built to demonstrate that modern cross-platform mobile frameworks can be tightly integrated with serverless backends and multi-agent AI configurations to deliver premium, low-latency, and context-aware consumer experiences in emerging markets.

### What Makes Bongo Foodie Different

1. **True Localized Logistics**: It doesn't rely solely on Google Maps API coordinates, which are notoriously imprecise in unmapped residential areas of Tanzania. Instead, it embeds a custom-seeded, relational Tanzania address hierarchy directly in the database.
2. **Voice-Enabled Chef AI**: A conversational assistant that speaks back to you in Swahili/English using low-latency ElevenLabs speech synthesis.
3. **Generative Dream Kitchen**: A feature allowing users to describe a custom meal (e.g., *"Nyama choma ya mbuzi yenye pilipili na ndizi kaanga"*), obtain a detailed recipe, see a generated photo of the dish, and order it as a custom item immediately.

---

## 📸 SECTION 2: LIVE SYSTEM SNAPSHOT

| Component                       | Status               | What It Does                                                                                                      | Tech Used                                                            |
| :------------------------------ | :------------------- | :---------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------- |
| **Mobile Client**         | 🟢 Fully Operational | Renders the primary user interface, routes between screens, manages local cart operations, and plays voice audio. | Expo SDK 54, React Native, TypeScript, Expo Router, Zustand, Expo AV |
| **Authentication Engine** | 🟢 Fully Operational | Handles user registration, sign-in, session persistence, and secure token storage.                                | Supabase Auth (JWT), Zustand Auth Store                              |
| **Relational Database**   | 🟢 Fully Operational | Stores normalized menus, categories, ingredients, customization items, and Tanzania locations.                    | PostgreSQL (Supabase), pg client                                     |
| **Location Compiler**     | 🟢 Fully Operational | Resolves manual address selections and filters districts/wards dynamically based on the selected region.          | Custom LocationPicker Component, Supabase DB                         |
| **Conversational AI**     | 🟢 Fully Operational | Chat Atelier assisting users with Swahili recipe pairings, structured to output under 3 sentences.                | Gemini Pro API (with rate-limiting key rotation)                     |
| **AI Composition Engine** | 🟢 Fully Operational | Receives custom prompts, builds structured JSON recipe specifications, and calculates macronutrients.             | Gemini Pro JSON schema mode                                          |
| **Image Generation**      | 🟢 Fully Operational | Generates highly realistic culinary photos of custom dishes described by the user.                                | SiliconFlow (Flux-1.0-Schnell API)                                   |
| **Voice Synthesizer**     | 🟢 Fully Operational | Converts Chef AI chat messages into natural spoken audio for user playback.                                       | ElevenLabs Text-to-Speech API                                        |

### What is Fully Working Right Now

* **Local Image Caching & Mapping**: Core Swahili dishes (Chipsi Mayai, Nyama Choma, Pilau ya Kuku, Samaki wa Kupaka, Mishkaki ya Ng'ombe) map directly to optimized local photographic assets instead of slow remote URLs, eliminating latency.
* **Location Picker Database**: The entire Tanzania locations database (66,978 records) is fully seeded and indexed on Supabase, allowing seamless Region ➔ District ➔ Ward cascading manual selection.
* **Grid and List View Toggling**: Dynamic layout toggling in the Search tab with custom styled `MenuRowCard` and `MenuCard` wrappers.
* **Zustand Global Cart Store**: Real-time addition, removal, quantity editing, custom item insertion, and cost calculations for orders.
* **ElevenLabs TTS Speech Player**: High-fidelity Swahili voice responses in the Chef AI Atelier.

### What is Partially Working

* **Stripe Payment Gateway**: The UI lists order calculations and a payment summary but the checkout action is currently simulated (mock checkout).
* **Profile Stats**: The statistics counters (e.g., "12 Total Orders") are static and need connection to a live order history aggregator.

### Planned but Not Started

* **Merchant Portal**: A separate Expo web app for restaurants to receive, accept, and track incoming delivery orders.
* **Real-time Driver Tracking**: WebSockets-backed map integration displaying live driver GPS coordinates on a MapView during delivery.

### What Was Tried and Abandoned

* *Appwrite Storage for Seed Images*: Originally, food images were hosted on Appwrite file storage. This was abandoned due to high cold-start image rendering latency on client mobile devices. It was replaced with local-first asset mapping and optimized Supabase public links.

---

## 📐 SECTION 3: SYSTEM ARCHITECTURE

### ASCII Architecture Diagram

```text
                  +----------------------------------------------+
                  |                 USER DEVICE                  |
                  |  +----------------------------------------+  |
                  |  |            React Native UI             |  |
                  |  |  +----------------------------------+  |  |
                  |  |  |   Expo Router / NativeWind v4    |  |  |
                  |  |  +----------------------------------+  |  |
                  |  +--------------------+-------------------+  |
                  +-----------------------|----------------------+
                                          |
                                HTTP / WebSockets
                                          |
                                          v
                  +-----------------------+----------------------+
                  |                SUPABASE BACKEND              |
                  |  +----------------------------------------+  |
                  |  |             Supabase Auth              |  |
                  |  +----------------------------------------+  |
                  |  |        PostgreSQL Database (DB)        |  |
                  |  |  +----------------------------------+  |  |
                  |  |  | - menu (local asset keys)        |  |  |
                  |  |  | - categories / customizations    |  |  |
                  |  |  | - regions / districts / wards     |  |  |
                  |  |  +----------------------------------+  |  |
                  |  +--------------------+-------------------+  |
                  +-----------------------|----------------------+
                                          |
                            External API Integrations
                                          |
                +-------------------------+-------------------------+
                |                                                   |
                v                                                   v
  +-------------+--------------+                      +-------------+--------------+
  |         GEMINI API         |                      |      ELEVENLABS API        |
  | (Rate-Limit Key Rotation)  |                      |    (Voice Synthesizer)     |
  |  - Conversational Chef     |                      |  - Low-Latency TTS Player  |
  |  - JSON Recipe Spec Output |                      +----------------------------+
  +-------------+--------------+
                |
                v
  +-------------+--------------+
  |      SILICONFLOW API       |
  | (Gourmet Image Generation) |
  |  - Flux-Schnell PNG Output |
  +----------------------------+
```

### Step-by-Step Code Execution: Creating & Ordering a Custom Dish

When a user describes a dish (e.g., *"Chipsi za mihogo na mishkaki"*):

1. **Form Input**: The text input is captured in `app/(tabs)/ai-chef.tsx` under the `creatorInput` state.
2. **API Call (Gemini)**: The system constructs a dynamic system prompt specifying a structured JSON response schema containing keys: `name`, `description`, `recipe`, `calories`, and `protein`.
3. **Key Rotation**: The prompt is processed by `lib/gemini.ts` which selects an active key from a list of 19 rotated Gemini keys in `.env` to avoid rate limits.
4. **SiliconFlow Flux Call**: Once the JSON recipe is generated, the app dispatches a concurrent HTTP POST request to `https://api.siliconflow.cn/v1/images/generations` requesting a photorealistic PNG of the custom dish.
5. **State Aggregation**: The generated image URL, title, recipe description, calories, and price (calculated dynamically at TSh 8,500 base) are loaded into the component state.
6. **Zustand Dispatch**: The user clicks "Add Custom Dish to Cart". The handler invokes `addItem()` in `store/cart.store.ts`, appending a new `CartItem` with a unique ID, flag `isAICreated: true`, and the generated image URI.
7. **Cart Render**: The `Cart` screen (`app/(tabs)/cart.tsx`) re-renders, displaying the custom item with its dynamic image and calculated subtotals.

---

## 📂 SECTION 4: COMPLETE FILE STRUCTURE

```text
food_ordering-main/
├── android/                   # Native Android build configurations and project files
├── assets/                    # Static image and font assets
│   ├── fonts/                 # Custom Outfit and Quicksand typography font files
│   └── images/                # Local photographic food assets (Nyama Choma, Chipsi Mayai, etc.)
├── app/                       # Expo Router application screens directory
│   ├── (auth)/                # Authentication routing group
│   │   ├── _layout.tsx        # Layout wrapper for authentication screens with login graphic
│   │   ├── sign-in.tsx        # User login screen with Appwrite/Supabase credentials check
│   │   └── sign-up.tsx        # User registration screen
│   ├── (tabs)/                # Main application tab routing group
│   │   ├── _layout.tsx        # Bottom tab bar navigator (labels hidden except for Home)
│   │   ├── ai-chef.tsx        # AI Chef Assistant (Chat Atelier and Gourmet Kitchen tabs)
│   │   ├── cart.tsx           # Cart review, payment summary, and location picker
│   │   ├── index.tsx          # Home page displaying seasonal campaigns and categories
│   │   ├── profile.tsx        # User profile, statistics, and interactive overlay modals
│   │   └── search.tsx         # Search screen with List/Grid view toggling
│   ├── _layout.tsx            # Global application root layout and Zustand store hydration
│   └── globals.css            # Global CSS styles compiled into NativeWind utility classes
├── components/                # Reusable UI components
│   ├── CartButton.tsx         # Floating header button displaying current cart item count
│   ├── CartItem.tsx           # Cart row component with quantity counters (local asset support)
│   ├── CustomButton.tsx       # Standardized primary button with loading states
│   ├── CustomHeader.tsx       # Screen header banner displaying title
│   ├── CustomInput.tsx        # Text input component with label styling and validation
│   ├── Filter.tsx             # Horizontal category filter slider bar
│   ├── LocationPicker.tsx     # GPS address resolver and cascading nested-scroll dropdowns
│   ├── MenuCard.tsx           # Grid menu card with local-first image resolution
│   ├── SearchBar.tsx          # Input text box for search query processing
│   └── TabBarIcon.tsx         # Custom icon rendering component for bottom tabs
├── constants/                 # Fixed application arrays and asset imports
│   └── index.ts               # Core categories, offers, and local image path dictionary
├── lib/                       # Backend configurations and third-party integrations
│   ├── appwrite.ts            # Legacy Appwrite configuration and file uploads
│   ├── gemini.ts              # Gemini LLM key rotation pool and JSON parser
│   ├── supabase.ts            # Supabase client instantiation and AsyncStorage configuration
│   ├── supabaseAuth.ts        # Supabase registration, login, and sign-out logic
│   ├── supabaseDb.ts          # Database query functions (getMenu, getCategories, Location queries)
│   └── useAppwrite.ts         # Generic query utility hook for handling loading states
├── scripts/                   # Database maintenance and import scripts
│   ├── create-admin.js        # Script to create admin role credentials
│   ├── import-locations.js    # Batch CSV parser importing Tanzania locations into Supabase
│   ├── run-migration.js       # SQL script runner to execute schema migrations via Pooler
│   ├── seed-supabase.js       # Populates menu, categories, and customizations in database
│   └── update-menu-images.js  # Updates menu rows image_url fields to local asset keys
├── store/                     # Global state management stores
│   ├── auth.store.ts          # Zustand store for user session states
│   ├── cart.store.ts          # Zustand store for cart items and order totals
│   └── location.store.ts      # Zustand store for global delivery address persistence
├── supabase/                  # Database migration configuration
│   └── schema.sql             # SQL database script defining tables, RLS, and triggers
├── tailwind.config.js         # Configuration settings for Tailwind CSS compilation
├── tsconfig.json              # TypeScript compiler configurations
├── package.json               # Project metadata, scripts, and dependency definitions
└── .env                       # Environment credentials and API keys (never committed)
```

---

## ⚙️ SECTION 5: INSTALLATION & SETUP

This setup guide is written step-by-step so that a developer of any level can install and run Bongo Foodie locally.

### Prerequisites

Before starting, download and install the following software:

1. **Node.js (v18.0.0 or higher)**: [Download Node.js](https://nodejs.org/en)
2. **Git**: [Download Git](https://git-scm.com/)
3. **Expo Go Mobile App**: Search for `Expo Go` on the Google Play Store or Apple App Store and install it on your physical test device.

---

### Step 1: Clone the Repository

Open your terminal (PowerShell on Windows or Terminal on macOS/Linux) and run:

```bash
git clone https://github.com/adrianhajdin/food_ordering.git
cd food_ordering
```

---

### Step 2: Install Project Dependencies

Install the required packages. We use the `--legacy-peer-deps` flag to resolve dependency conflicts between Expo and React Native Reanimated:

```bash
npm install --legacy-peer-deps
```

---

### Step 3: Configure Environment Variables

Create a file named `.env` in the root of the project:

```bash
New-Item -Path .env -ItemType File
```

*(Or use `touch .env` on macOS/Linux)*

Open the `.env` file and populate it with the following credentials:

```env
# Supabase Configuration
EXPO_PUBLIC_SUPABASE_URL=https://rkjanbxkgfyjpdcichvy.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_secret_service_key
SUPABASE_DB_PASSWORD=your_db_password
SUPABASE_POOLER_URL=postgres://postgres.your_project_ref:your_password@aws-1-eu-central-2.pooler.supabase.com:6543/postgres

# Gemini API Keys (Rotated pool, comma-separated)
EXPO_PUBLIC_GEMINI_KEYS=key1,key2,key3

# ElevenLabs (TTS Voice Synthesis)
EXPO_PUBLIC_ELEVENLABS_KEYS=your_elevenlabs_key

# SiliconFlow API Key (Image Generation)
EXPO_PUBLIC_SILICONFLOW_KEY=your_siliconflow_key
```

---

### Step 4: Run Database Migrations

Deploy the database schema to your Supabase instance:

```bash
node scripts/run-migration.js
```

*Expected Output*:

```text
Connecting via pooler: postgres://postgres:****@aws-1-eu-central-2.pooler.supabase.com:6543/postgres...
Ref: rkjanbxkgfyjpdcichvy
✅ Connected! Executing schema.sql statements...
🎉 Schema migration completed successfully!
```

---

### Step 5: Seed the Database

Seed the categories, customization items, and menu items:

```bash
node scripts/seed-supabase.js
```

*Expected Output*:

```text
Seeding database...
✅ Categories seeded successfully.
✅ Customization items seeded.
✅ Menu items seeded and mapped.
🎉 Supabase database seeding complete!
```

---

### Step 6: Import Tanzania Locations Database

To populate the 66,978 local Tanzanian regions, districts, and wards, run the location importer:

```bash
node scripts/import-locations.js
```

*Expected Output*:

```text
Connecting to Supabase Database for Location Import...
✅ Connected!
Creating tables...
✅ Tables and indexes created.
Reading 26 CSV files...
Parsed 66978 general rows. Importing into 'general' in batches...
  Inserted 10000/66978 rows...
  ...
  Inserted 66978/66978 rows...
Updating country_id on general table...
✅ General locations fully imported.
Running extract.sql to populate regions, districts, wards, and places tables...
🎉 Tanzania Locations Database successfully imported & compiled in Supabase!
```

---

### Step 7: Update Menu Image Asset Keys

Update the database menu records to resolve to local optimized asset files:

```bash
node scripts/update-menu-images.js
```

*Expected Output*:

```text
Updating menu image_url records in database...
✅ Updated Chipsi Mayai image_url to 'chipsiMayai'
✅ Updated Nyama Choma & Ugali image_url to 'nyamaChoma'
...
🎉 Menu image URLs updated successfully!
```

---

### Step 8: Start the Expo Development Server

Start the Metro bundler:

```bash
npx expo start -c
```

Press **`a`** to run on an Android Emulator, **`i`** to run on an iOS Simulator, or scan the displayed QR code with your Expo Go app to run directly on your physical mobile device!

---

### Setup Troubleshooting Cheatsheet

* **Error: `[BABEL] Cannot find module 'react-native-reanimated/plugin'`**
  * *Cause*: Babel compilation cache is stale.
  * *Fix*: Stop the server and start with clear cache: `npx expo start -c`.
* **Error: `MODULE_NOT_FOUND` when running scripts**
  * *Cause*: Running scripts outside of the project root or before `npm install`.
  * *Fix*: Ensure you run scripts from the project root directory where `node_modules` is located.
* **Error: `Invalid Login Credentials` in Supabase Auth**
  * *Cause*: The user has not signed up, or the environment variables are not correctly resolved by Expo.
  * *Fix*: Register a new account via the Sign Up tab first. Ensure all variables in `.env` are prefixed with `EXPO_PUBLIC_` for runtime visibility.

---

## 📝 SECTION 6: HOW TO USE IT

### 1. Conversational Chef AI (Chat Atelier)

* **What it does**: Users ask culinary questions. Chef AI answers in Swahili or English within a strict 3-sentence constraint to fit mobile layouts.
* **Implementation Flow**:
  ```typescript
  import { askChef } from "@/lib/gemini";
  const reply = await askChef("Jinsi ya kupika chipsi mayai?");
  console.log(reply);
  // Output: "Kwanza kaanga viazi hadi viive. Kisha changanya mayai na kumwaga juu ya viazi kwenye kikaango. Geuza keki ya viazi na mayai upande wa pili kisha andaa na kachumbari."
  ```

### 2. ElevenLabs Text-to-Speech synthesis

* **What it does**: Synthesizes speech from Chef AI text replies so the user can listen to the recipe audio.
* **HTTP API Request**:
  ```bash
  curl -X POST "https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM" \
       -H "xi-api-key: YOUR_ELEVENLABS_KEY" \
       -H "Content-Type: application/json" \
       -d '{"text": "Karibu Bongo Foodie. Naitwa Chef AI, msaidizi wako.", "model_id": "eleven_monolingual_v1"}' \
       --output voice.mp3
  ```
* **Edge Case**: API returns `401 Unauthorized` if the key is missing or quota is exhausted. The client falls back silently to display only text, showing a toast error: *"Audio synthesis unavailable."*

### 3. Gourmet Kitchen Custom Dish Generation

* **What it does**: Generates a high-quality photorealistic image and recipe details based on a custom text input prompt.
* **HTTP Image Generation Request (SiliconFlow)**:
  ```bash
  curl -X POST "https://api.siliconflow.cn/v1/images/generations" \
       -H "Authorization: Bearer YOUR_SILICONFLOW_KEY" \
       -H "Content-Type: application/json" \
       -d '{
             "model": "black-forest-labs/FLUX.1-schnell",
             "prompt": "An isolated food photo of Chipsi ya mihogo na mishkaki, white background, PNG style",
             "width": 512,
             "height": 512,
             "num_inference_steps": 4
           }'
  ```
* **API Response**:
  ```json
  {
    "images": [
      { "url": "https://sf-cdn.siliconflow.cn/generations/abc123xyz.png" }
    ]
  }
  ```

---

## 🗄️ SECTION 7: DATABASE SCHEMA

Bongo Foodie uses Supabase PostgreSQL for high-performance relational mapping.

### 1. Table: `profiles`

Stores user profile information synced to Supabase Auth.

* `id` (uuid, Primary Key) ➔ References `auth.users.id`
* `name` (text) ➔ User full name (e.g. *"Juma Hamisi"*)
* `email` (text) ➔ User email address
* `avatar_url` (text) ➔ Optional public avatar URL
* *Indexes*: Automatically indexed on `id` (primary key).

### 2. Table: `categories`

Stores food category divisions.

* `id` (uuid, Primary Key) ➔ Generated defaults.
* `name` (text, Unique) ➔ Category names (e.g. *"Swahili Bites"*)
* `description` (text) ➔ Description of culinary group

### 3. Table: `customizations`

Stores customizable add-ons (toppings, sides, drinks).

* `id` (uuid, Primary Key)
* `name` (text, Unique) ➔ Add-on name (e.g. *"Kachumbari Extra"*)
* `price` (numeric) ➔ Cost (e.g. `1000` TSh)
* `type` (text) ➔ Type category (e.g. `"topping"`, `"side"`)

### 4. Table: `menu`

Stores primary food menu entries.

* `id` (uuid, Primary Key)
* `name` (text, Unique) ➔ Name of dish (e.g. *"Chipsi Mayai"*)
* `description` (text) ➔ Ingredients and descriptions
* `image_url` (text) ➔ Maps to local asset keys (`"chipsiMayai"`) or remote URLs
* `price` (numeric) ➔ Cost of item (e.g. `5000`)
* `rating` (numeric) ➔ Food rating value (e.g. `4.8`)
* `category_id` (uuid) ➔ Foreign Key references `categories.id`
* *Indexes*: Index created on `category_id` for fast query filtering.

### 5. Table: `regions`

Stores Tanzanian regions.

* `region_code` (integer, Primary Key)
* `region_name` (text) ➔ Region title (e.g. *"Dar es Salaam"*)

---

## 🤖 SECTION 8: AI INTEGRATION DETAILS

### Models Selected & Rationale

1. **Gemini 1.5 Pro / Flash**: Excellent multilingual understanding of Swahili idioms. Cost-effective and supports structured JSON outputs via schema declaration.
2. **Flux-1.0-Schnell (SiliconFlow)**: Selected for its state-of-the-art capability to render photorealistic food compositions in under 3 seconds using latent consistency models.

### AI Prompt Construction

The system constructs system prompts dynamically to ensure format alignment.

* **System Prompt for Chat**:
  ```text
  You are Chef AI, an expert Swahili culinary chef. Help the user with recipes, Swahili food pairings, and kitchen tips.
  CRITICAL: Keep your response short and engaging - maximum of 3 sentences. Write in Swahili or English.
  ```
* **System Prompt for Recipe Specifications**:
  ```text
  Generate a JSON specification for the custom Swahili dish requested.
  Schema:
  {
    "name": "string (Swahili Title)",
    "description": "string (Short English description)",
    "recipe": "string (3-step preparation in Swahili)",
    "calories": number,
    "protein": number
  }
  ```

### Rate-Limiting Failover (Key Rotation Pool)

To guarantee high availability without premium tier enterprise AI subscriptions, the system implements an active key rotation pool in `lib/gemini.ts`.

```typescript
const keys = process.env.EXPO_PUBLIC_GEMINI_KEYS?.split(',') || [];
let currentKeyIndex = 0;

export function getActiveApiKey() {
    const key = keys[currentKeyIndex];
    currentKeyIndex = (currentKeyIndex + 1) % keys.length; // Rotate for next call
    return key;
}
```

If an API call returns a `429 Too Many Requests` error, the handler catches the error, rotates the index immediately, and retries the call.

---

## 🔴 SECTION 9: CURRENT LIMITATIONS & KNOWN BUGS

### Brutally Honest Limitations & Bugs

1. **Cart Customization Sync**: Selecting customizations (e.g. adding extra Kachumbari) on the detail card adds them to the cart item's meta fields, but does not multiply the cost of the customizations inside the subtotal aggregate yet.
2. **Stripe Simulation Limit**: The checkout process simulates payment completion via a mock delay timer instead of executing real-world credit card verification or mobile money (M-Pesa, Tigopesa) API transactions.
3. **GPS Geocoder Timeout**: Under poor mobile data connections in outlying Tanzanian wards, reverse-geocoding coordinates can time out, returning a generic GPS location string rather than resolved street/ward titles.
4. **Zustand Profile Stat Hydration**: If the app is launched cold (from terminated state), the total orders counter is reset to dummy defaults until a new order session is initiated.

---

## 🔌 SECTION 10: MODIFICATION & ADDON GUIDE

### MOD NAME: Adding M-Pesa Mobile Money Payments

* **Difficulty**: ⭐⭐⭐⭐ (4/5 stars)
* **Time to implement**: 3 days
* **Files to modify**:
  * `app/(tabs)/cart.tsx`
  * `store/cart.store.ts`
* **New files to create**:
  * `lib/mpesa.ts` (Vodacom M-Pesa API client wrapper)
* **Dependencies to add**:
  * `npm install crypto-js`
* **Implementation Steps**:
  1. Create `lib/mpesa.ts` containing the standard Open API OAuth token request and C2B (Customer to Business) payment push request logic.
  2. Update the checkout button in `app/(tabs)/cart.tsx` to collect the user's phone number and trigger the M-Pesa STK push.
  3. Await the transaction response callback from the Vodacom server, and push the completed order to Supabase.
* **How to test**: Run in the Vodacom Sandbox environment and verify that the USSD push notification triggers on your testing phone.

---

## 🪂 SECTION 11: DEPLOYMENT GUIDE

### Deployment to Vercel (Web / Bundles Hosting)

1. Initialize Expo Web Export:
   ```bash
   npx expo export
   ```
2. Deploy the generated `dist` folder to Vercel or Netlify.
3. Add the environment variables in your Vercel Project Settings panel.

### Database Security Rules

To ensure secure data access, configure Row Level Security (RLS) on your Supabase tables.
Example RLS Rule for profiles:

```sql
create policy "Users can modify their own profiles."
  on public.profiles
  for all
  using (auth.uid() = id);
```

Ensure RLS is enabled on all tables:

```sql
alter table public.profiles enable row level security;
alter table public.menu enable row level security;
```

---

## 📊 SECTION 12: COST CALCULATOR

Estimated monthly operational expenses in USD.

| Service                     | Free Tier Limits          | Paid Tier Pricing                          | Cost (100 Users)                 | Cost (1000 Users) |
| :-------------------------- | :------------------------ | :----------------------------------------- | :------------------------------- | :---------------- |
| **Supabase Database** | 500 MB DB storage         | $25 / month | $0.00                        | $0.00 (within limits)            |                   |
| **Gemini API**        | 15 RPM / 1M TPM           | Pay-per-token model                        | $0.00 (rotated key pool) | $2.50 |                   |
| **ElevenLabs TTS**    | 10,000 characters/mo      | $5 / month | $0.00                         | $15.00                           |                   |
| **SiliconFlow Flux**  | 14 USD free trial credits | $0.00015 per image | $0.00 (trial credits) | $0.75                            |                   |
| **Expo EAS Updates**  | 1,000 monthly updates     | $0.005 per update | $0.00                  | $0.00                            |                   |

---

## 🗺️ SECTION 13: ROADMAP

### Short-Term (Next 2 Weeks)

- [ ] Connect profile statistics indicators to dynamic aggregations of completed cart checkouts.
- [ ] Fix customization subtotal calculations in `store/cart.store.ts`.
- [ ] Add Swahili language audio localization toggle in settings.
- [ ] Implement search history storage.
- [ ] Support password reset flows in authentication.

### Medium-Term (Next 3 Months)

- [ ] Build the Merchant Portal Expo Web project for vendor management.
- [ ] Set up SMS receipt delivery utilizing Twilio/Appwrite SMS triggers.
- [ ] Connect live driver MapView route tracking utilizing Mapbox SDK.

### Long-Term (6-12 Months)

- [ ] Deploy Bongo Foodie across major cities in East Africa (Nairobi, Mombasa, Kampala).
- [ ] Integrate predictive demand AI to forecast ingredient inventory for popular vendors.

---

## 💡 SECTION 14: LESSONS LEARNED

* **Local Image Caching is Vital**: In mobile development for regions with unstable cellular data, serving large assets over public CDN servers creates an unacceptable user experience. Mapping static assets to localized directories in React Native resolves lag immediately.
* **Postgres Cascading Dropdowns**: Normalizing geography databases (Region ➔ District ➔ Ward) and querying them dynamically via Supabase yields a much higher UX completion rate than raw text fields.
* **Key Rotation Strategies**: Simple array rotations for API keys in standard configurations allow developers to easily prototype resource-intensive projects during beta phases without incurring large backend debts.

---

## 🎛️ SECTION 15: QUICK REFERENCE CARD

### Most Important Commands

* **Start Local Bundler**: `npx expo start -c`
* **Seeding Supabase**: `node scripts/seed-supabase.js`
* **Location Database Importer**: `node scripts/import-locations.js`
* **Export Production Bundle**: `npx expo export`

### Key Environment Variables

* `EXPO_PUBLIC_SUPABASE_URL` ➔ Base Supabase endpoint
* `EXPO_PUBLIC_SUPABASE_ANON_KEY` ➔ Public client token
* `SUPABASE_SERVICE_ROLE_KEY` ➔ Admin bypass credentials
* `EXPO_PUBLIC_GEMINI_KEYS` ➔ Rotated Gemini API key string

### File Map

* **Cart Actions**: [cart.store.ts](<file:///c:/Users/MWIJAY%20TECH/Desktop/PROJECTS/food_ordering-main/store/cart.store.ts>)
* **Database Queries**: [supabaseDb.ts](<file:///c:/Users/MWIJAY%20TECH/Desktop/PROJECTS/food_ordering-main/lib/supabaseDb.ts>)
* **AI Handlers**: [gemini.ts](<file:///c:/Users/MWIJAY%20TECH/Desktop/PROJECTS/food_ordering-main/lib/gemini.ts>)
* **Geography picker**: [LocationPicker.tsx](<file:///c:/Users/MWIJAY%20TECH/Desktop/PROJECTS/food_ordering-main/components/LocationPicker.tsx>)
