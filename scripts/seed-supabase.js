const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');

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

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL || '';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ Error: EXPO_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing in .env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    persistSession: false,
  },
});

const dummyData = {
  categories: [
    { name: "Swahili Bites", description: "Traditional East African starters" },
    { name: "Nyama Choma", description: "Flame-grilled signature meats" },
    { name: "Rice & Pilau", description: "Fragrant rice main courses" },
    { name: "Traditional Stews", description: "Slow-cooked coconut stews" },
    { name: "Vinywaji", description: "Refreshing local drinks" },
  ],

  customizations: [
    { name: "Kachumbari Extra", price: 1000, type: "topping" },
    { name: "Pili Pili Kali", price: 500, type: "topping" },
    { name: "Ndimu (Lime)", price: 300, type: "topping" },
    { name: "Ndizi Kaanga Extra", price: 1500, type: "topping" },
    { name: "Avocado Slices", price: 1000, type: "topping" },
    { name: "Cheese slice", price: 1200, type: "topping" },
    { name: "Stoney Tangawizi", price: 1500, type: "side" },
    { name: "Chips Kaanga", price: 2500, type: "side" },
    { name: "Ugali Kipande", price: 1000, type: "side" },
    { name: "Mchicha wa Nazi", price: 1500, type: "side" },
    { name: "Juisi ya Passion", price: 2000, type: "side" },
    { name: "Chai ya Rangi", price: 1000, type: "side" },
    { name: "Maji ya Kisima", price: 1000, type: "side" },
  ],

  menu: [
    {
      name: "Chipsi Mayai",
      description: "French fry omelette, fresh kachumbari, pili pili sauce",
      image_url:
        "https://static.vecteezy.com/system/resources/previews/044/844/600/large_2x/homemade-fresh-tasty-burger-with-meat-and-cheese-classic-cheese-burger-and-vegetable-ai-generated-free-png.png",
      price: 5000,
      rating: 4.8,
      calories: 580,
      protein: 16,
      category_name: "Swahili Bites",
      customizations: ["Kachumbari Extra", "Pili Pili Kali", "Chips Kaanga", "Stoney Tangawizi"],
    },
    {
      name: "Nyama Choma & Ugali",
      description: "Flame-grilled beef ribs, hot ugali, mchicha, and kachumbari",
      image_url:
        "https://static.vecteezy.com/system/resources/previews/023/742/417/large_2x/pepperoni-pizza-isolated-illustration-ai-generative-free-png.png",
      price: 12000,
      rating: 4.9,
      calories: 780,
      protein: 42,
      category_name: "Nyama Choma",
      customizations: [
        "Kachumbari Extra",
        "Pili Pili Kali",
        "Mchicha wa Nazi",
        "Stoney Tangawizi",
        "Ugali Kipande",
      ],
    },
    {
      name: "Pilau ya Kuku",
      description: "Fragrant spiced pilau rice, chicken stew, kachumbari",
      image_url:
        "https://static.vecteezy.com/system/resources/previews/055/133/581/large_2x/deliciously-grilled-burritos-filled-with-beans-corn-and-fresh-vegetables-served-with-lime-wedge-and-cilantro-isolated-on-transparent-background-free-png.png",
      price: 9500,
      rating: 4.7,
      calories: 620,
      protein: 28,
      category_name: "Rice & Pilau",
      customizations: ["Kachumbari Extra", "Juisi ya Passion", "Avocado Slices", "Pili Pili Kali"],
    },
    {
      name: "Samaki wa Kupaka",
      description: "Charcoal-grilled fish coated in a rich, spiced coconut curry sauce",
      image_url:
        "https://static.vecteezy.com/system/resources/previews/060/236/245/large_2x/a-large-hamburger-with-cheese-onions-and-lettuce-free-png.png",
      price: 14000,
      rating: 4.9,
      calories: 690,
      protein: 38,
      category_name: "Traditional Stews",
      customizations: ["Ndimu (Lime)", "Mchicha wa Nazi", "Maji ya Kisima", "Juisi ya Passion"],
    },
    {
      name: "Mishkaki ya Ng'ombe",
      description: "Three beef skewers marinated in Swahili ginger-garlic spice blend",
      image_url:
        "https://static.vecteezy.com/system/resources/previews/048/930/603/large_2x/caesar-wrap-grilled-chicken-isolated-on-transparent-background-free-png.png",
      price: 6000,
      rating: 4.6,
      calories: 450,
      protein: 32,
      category_name: "Nyama Choma",
      customizations: ["Pili Pili Kali", "Stoney Tangawizi", "Chips Kaanga", "Kachumbari Extra"],
    },
    {
      name: "Wali wa Nazi na Maharage",
      description: "Creamy coconut rice served with spiced red kidney beans coconut stew",
      image_url:
        "https://static.vecteezy.com/system/resources/previews/047/832/012/large_2x/grilled-sesame-seed-bread-veggie-sandwich-with-tomato-and-onion-free-png.png",
      price: 4500,
      rating: 4.4,
      calories: 520,
      protein: 14,
      category_name: "Rice & Pilau",
      customizations: ["Mchicha wa Nazi", "Avocado Slices", "Juisi ya Passion", "Chai ya Rangi"],
    },
    {
      name: "Ndizi Kaanga",
      description: "Crispy sweet fried plantains, a popular coastal snack",
      image_url:
        "https://static.vecteezy.com/system/resources/previews/057/913/530/large_2x/delicious-wraps-a-tantalizing-array-of-wraps-filled-with-vibrant-vegetables-succulent-fillings-and-fresh-ingredients-artfully-arranged-for-a-mouthwatering-culinary-experience-free-png.png",
      price: 3000,
      rating: 4.5,
      calories: 310,
      protein: 3,
      category_name: "Swahili Bites",
      customizations: ["Ndimu (Lime)", "Chai ya Rangi", "Juisi ya Passion"],
    },
    {
      name: "Mchuzi wa Kuku na Chapati",
      description: "Thick chicken curry stew served with two layered flaky chapati",
      image_url:
        "https://static.vecteezy.com/system/resources/previews/057/466/374/large_2x/healthy-quinoa-bowl-with-avocado-tomato-and-black-beans-ingredients-free-png.png",
      price: 8000,
      rating: 4.8,
      calories: 640,
      protein: 26,
      category_name: "Traditional Stews",
      customizations: ["Avocado Slices", "Pili Pili Kali", "Juisi ya Passion"],
    },
  ],
};

async function seed() {
  console.log(`Connecting to Supabase at: ${supabaseUrl}...`);
  console.log('Clearing old data in Supabase...');
  
  try {
    await supabase.from('menu_customizations').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    await supabase.from('menu').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    await supabase.from('customizations').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    await supabase.from('categories').delete().neq('id', '00000000-0000-0000-0000-000000000000');

    console.log('Seeding Categories...');
    const categoryMap = {};
    for (const cat of dummyData.categories) {
      const { data, error } = await supabase
        .from('categories')
        .insert({ name: cat.name, description: cat.description })
        .select();
      
      if (error) throw error;
      categoryMap[cat.name] = data[0].id;
    }
    console.log('Categories seeded successfully.');

    console.log('Seeding Customizations...');
    const customizationMap = {};
    for (const cust of dummyData.customizations) {
      const { data, error } = await supabase
        .from('customizations')
        .insert({ name: cust.name, price: cust.price, type: cust.type })
        .select();

      if (error) throw error;
      customizationMap[cust.name] = data[0].id;
    }
    console.log('Customizations seeded successfully.');

    console.log('Seeding Menu Items...');
    for (const item of dummyData.menu) {
      const categoryId = categoryMap[item.category_name];
      const { data, error } = await supabase
        .from('menu')
        .insert({
          name: item.name,
          description: item.description,
          image_url: item.image_url,
          price: item.price,
          rating: item.rating,
          calories: item.calories,
          protein: item.protein,
          category_id: categoryId,
        })
        .select();

      if (error) throw error;

      const menuItemId = data[0].id;

      // Seed menu customizations association
      for (const custName of item.customizations) {
        const customizationId = customizationMap[custName];
        if (customizationId) {
          const { error: assocError } = await supabase
            .from('menu_customizations')
            .insert({
              menu_id: menuItemId,
              customization_id: customizationId,
            });

          if (assocError) throw assocError;
        }
      }
    }

    console.log('🎉 Seeding completed successfully!');
  } catch (error) {
    console.error('❌ Seeding failed:', error.message);
  }
}

seed();
