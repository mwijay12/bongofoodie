const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

// Pure JS .env parser to avoid extra dependency issues
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

const sqlPath = path.join(__dirname, '../supabase/schema.sql');
const sql = fs.readFileSync(sqlPath, 'utf8');

let connectionString = process.env.SUPABASE_POOLER_URL || '';

if (!connectionString) {
  // Extract project reference from the URL: https://<ref>.supabase.co
  const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL || '';
  const projectRefMatch = supabaseUrl.match(/https:\/\/([\w-]+)\.supabase\.co/);
  const projectRef = projectRefMatch ? projectRefMatch[1] : '';
  const dbPassword = process.env.SUPABASE_DB_PASSWORD || '';

  if (!projectRef || !dbPassword) {
    console.error('❌ Error: SUPABASE_POOLER_URL, EXPO_PUBLIC_SUPABASE_URL, or SUPABASE_DB_PASSWORD missing in .env');
    process.exit(1);
  }

  // Database Host name is lowercased project-ref
  const host = `db.${projectRef.toLowerCase()}.supabase.co`;
  connectionString = `postgres://postgres:${dbPassword}@${host}:6543/postgres`;
  console.log(`Connecting to direct database host: ${host}...`);
} else {
  // Hide password in console log
  const maskedConn = connectionString.replace(/:([^:@]+)@/, ':****@');
  console.log(`Connecting via pooler: ${maskedConn}...`);
}

const client = new Client({
  connectionString: connectionString,
  ssl: {
    rejectUnauthorized: false
  }
});

async function main() {
  try {
    await client.connect();
    console.log('✅ Connected! Executing schema.sql statements...');
    await client.query(sql);
    console.log('🎉 Schema migration completed successfully!');
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    console.log('\nTip: If you get ENOTFOUND, make sure your EXPO_PUBLIC_SUPABASE_URL in .env has the correct project reference.');
  } finally {
    await client.end();
  }
}

main();
