const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

let supabaseUrl = 'https://rkjanbxkgfyjpdcichvy.supabase.co';
let supabaseServiceKey = '';

if (fs.existsSync('.env')) {
  const envContent = fs.readFileSync('.env', 'utf8');
  const urlMatch = envContent.match(/EXPO_PUBLIC_SUPABASE_URL\s*=\s*(.*)/);
  const keyMatch = envContent.match(/SUPABASE_SERVICE_ROLE_KEY\s*=\s*(.*)/);
  if (urlMatch) supabaseUrl = urlMatch[1].trim();
  if (keyMatch) supabaseServiceKey = keyMatch[1].trim();
}

if (!supabaseServiceKey) {
  console.error('❌ SUPABASE_SERVICE_ROLE_KEY missing in .env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function main() {
  console.log('Updating menu image_url records in database...');
  
  const updates = [
    { name: "Chipsi Mayai", image_url: "chipsiMayai" },
    { name: "Nyama Choma & Ugali", image_url: "nyamaChoma" },
    { name: "Pilau ya Kuku", image_url: "pilauYaKuku" },
    { name: "Samaki wa Kupaka", image_url: "samakiWaKupaka" },
    { name: "Mishkaki ya Ng'ombe", image_url: "mishkakiYaNgombe" }
  ];

  for (const item of updates) {
    const { data, error } = await supabase
      .from('menu')
      .update({ image_url: item.image_url })
      .eq('name', item.name)
      .select();

    if (error) {
      console.error(`❌ Failed to update ${item.name}:`, error.message);
    } else {
      console.log(`✅ Updated ${item.name} image_url to '${item.image_url}'`);
    }
  }

  console.log('🎉 Menu image URLs updated successfully!');
}

main().catch(console.error);
