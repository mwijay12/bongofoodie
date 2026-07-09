const dummyData = {
    categories: [
        { name: "Swahili Bites", description: "Traditional East African starters" },
        { name: "Nyama Choma", description: "Flame-grilled signature meats" },
        { name: "Rice & Pilau", description: "Fragrant rice main courses" },
        { name: "Traditional Stews", description: "Slow-cooked coconut stews" },
        { name: "Vinywaji", description: "Refreshing local drinks" },
    ],

    customizations: [
        // Toppings & Extras
        { name: "Kachumbari Extra", price: 1000, type: "topping" },
        { name: "Pili Pili Kali", price: 500, type: "topping" },
        { name: "Ndimu (Lime)", price: 300, type: "topping" },
        { name: "Ndizi Kaanga Extra", price: 1500, type: "topping" },
        { name: "Avocado Slices", price: 1000, type: "topping" },
        { name: "Cheese slice", price: 1200, type: "topping" },

        // Sides & Drinks
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
                "https://static.vecteezy.com/system/resources/previews/044/844/600/large_2x/homemade-fresh-tasty-burger-with-meat-and-cheese-classic-cheese-burger-and-vegetable-ai-generated-free-png.png", // keeping structural placeholder URL
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

export default dummyData;
