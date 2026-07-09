const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

// Load environment variables from .env
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

const connectionString = process.env.SUPABASE_POOLER_URL;
if (!connectionString) {
  console.error('❌ Error: SUPABASE_POOLER_URL is missing in .env');
  process.exit(1);
}

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

const locDbDir = path.join(__dirname, '../../tanzania-locations-db-main');

async function main() {
  console.log('Connecting to Supabase Database for Location Import...');
  await client.connect();
  console.log('✅ Connected!');

  // 1. Create Tables
  console.log('Creating tables...');
  let creationSql = fs.readFileSync(path.join(locDbDir, 'sql-scripts/tables_creation.sql'), 'utf8');
  // Make drops safe so they don't crash if running for first time
  creationSql = creationSql.replace(/DROP TABLE (\w+) CASCADE;/g, 'DROP TABLE IF EXISTS $1 CASCADE;');
  await client.query(creationSql);
  console.log('✅ Tables and indexes created.');

  // 2. Insert countries
  console.log('Inserting countries...');
  const countriesSql = fs.readFileSync(path.join(locDbDir, 'sql-scripts/countries.sql'), 'utf8');
  await client.query(countriesSql);
  console.log('✅ Countries inserted.');

  // 3. Read and Import CSVs
  const csvDir = path.join(locDbDir, 'location-files');
  const files = fs.readdirSync(csvDir).filter(f => f.endsWith('.csv'));
  
  console.log(`Reading ${files.length} CSV files...`);
  const rows = [];
  
  for (const file of files) {
    const filePath = path.join(csvDir, file);
    const content = fs.readFileSync(filePath, 'utf8');
    const lines = content.split(/\r?\n/);
    
    for (let i = 1; i < lines.length; i++) {
      const line = lines[i].trim();
      if (!line) continue;
      
      const cols = line.split(',');
      if (cols.length < 6) continue;
      
      const regioncode = parseInt(cols[1], 10);
      const districtcode = parseInt(cols[3], 10);
      const wardcode = parseInt(cols[5], 10);

      if (isNaN(regioncode) || isNaN(districtcode) || isNaN(wardcode)) {
        // Skip invalid rows or headers
        continue;
      }
      
      rows.push({
        region: cols[0],
        regioncode,
        district: cols[2],
        districtcode,
        ward: cols[4],
        wardcode,
        street: cols[6] || null,
        places: cols[7] || null
      });
    }
  }

  console.log(`Parsed ${rows.length} general rows. Importing into 'general' in batches...`);
  
  const batchSize = 1000;
  for (let i = 0; i < rows.length; i += batchSize) {
    const batch = rows.slice(i, i + batchSize);
    
    let queryText = 'INSERT INTO general (region, regioncode, district, districtcode, ward, wardcode, street, places) VALUES ';
    const queryParams = [];
    
    batch.forEach((row, rowIndex) => {
      const offset = rowIndex * 8;
      queryText += `($${offset + 1}, $${offset + 2}, $${offset + 3}, $${offset + 4}, $${offset + 5}, $${offset + 6}, $${offset + 7}, $${offset + 8})${rowIndex === batch.length - 1 ? '' : ', '}`;
      queryParams.push(row.region, row.regioncode, row.district, row.districtcode, row.ward, row.wardcode, row.street, row.places);
    });

    await client.query(queryText, queryParams);
    
    if ((i + batch.length) % 10000 === 0 || i + batch.length === rows.length) {
      console.log(`  Inserted ${i + batch.length}/${rows.length} rows...`);
    }
  }
  
  console.log('Updating country_id on general table...');
  await client.query('UPDATE general SET country_id = 210;');
  console.log('✅ General locations fully imported.');

  // 4. Running extract.sql
  console.log('Running extract.sql to populate regions, districts, wards, and places tables...');
  const extractSql = fs.readFileSync(path.join(locDbDir, 'sql-scripts/extract.sql'), 'utf8');
  
  // We need to run extract.sql. Since pg doesn't support multiple functions and queries in one call with parameters,
  // we can just run the script as a single query since pg client allows multi-statement raw SQL without parameters.
  await client.query(extractSql);
  
  console.log('🎉 Tanzania Locations Database successfully imported & compiled in Supabase!');
  await client.end();
}

main().catch(err => {
  console.error('❌ Import failed:', err);
  client.end().catch(() => {});
});
