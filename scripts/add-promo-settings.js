const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

function loadEnv() {
  const envPath = path.join(__dirname, '../.env');
  if (fs.existsSync(envPath)) {
    const envContent = fs.readFileSync(envPath, 'utf8');
    envContent.split(/\r?\n/).forEach(line => {
      const match = line.match(/^\s*([\w.-]+)\s*=\s*(.*)?\s*$/);
      if (match) {
        const key = match[1];
        let value = match[2] || '';
        if (value.startsWith('"') && value.endsWith('"')) value = value.slice(1, -1);
        if (value.startsWith("'") && value.endsWith("'")) value = value.slice(1, -1);
        process.env[key] = value;
      }
    });
  }
}

loadEnv();

let connectionString = process.env.SUPABASE_POOLER_URL || '';

if (!connectionString) {
  const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL || '';
  const projectRefMatch = supabaseUrl.match(/https:\/\/([\w-]+)\.supabase\.co/);
  const projectRef = projectRefMatch ? projectRefMatch[1] : '';
  const dbPassword = process.env.SUPABASE_DB_PASSWORD || '';
  const host = `db.${projectRef.toLowerCase()}.supabase.co`;
  connectionString = `postgres://postgres:${dbPassword}@${host}:6543/postgres`;
}

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

async function main() {
  try {
    await client.connect();
    console.log('Connected! Adding promo columns to settings table...');
    
    // Add columns if they do not exist
    await client.query(`
      ALTER TABLE public.settings 
      ADD COLUMN IF NOT EXISTS promo_code text DEFAULT 'KARIBU2000',
      ADD COLUMN IF NOT EXISTS promo_discount numeric DEFAULT 2000,
      ADD COLUMN IF NOT EXISTS promo_active boolean DEFAULT true;
    `);
    
    console.log('🎉 Promo settings columns added successfully!');
  } catch (err) {
    console.error('❌ Error executing SQL:', err.message);
  } finally {
    await client.end();
  }
}

main();
