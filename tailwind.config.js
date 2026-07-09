/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./app/**/*.{js,jsx,ts,tsx}", "./components/**/*.{js,jsx,ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        primary: "#F6821F", // Swahili Orange primary
        white: {
          DEFAULT: "#ffffff",
          100: "#FBFBFA", // warm bone bg color
          200: "#F6821F",
        },
        gray: {
          100: "#878787",
          200: "#787774", // editorial gray
        },
        dark: {
          100: "#181C2E", // charcoal text
        },
        gourmet: {
          bone: "#FBFBFA",
          forest: "#F6821F", // mapped forest to Swahili Orange
          amber: "#FBAD41",  // mapped amber to golden/yellow orange
          charcoal: "#181C2E",
          border: "#EAEAEA",
        },
        error: "#F14141",
        success: "#2F9B65",
      },
      fontFamily: {
        quicksand: ["Quicksand-Regular", "sans-serif"],
        "quicksand-bold": ["Quicksand-Bold", "sans-serif"],
        "quicksand-semibold": ["Quicksand-SemiBold", "sans-serif"],
        "quicksand-light": ["Quicksand-Light", "sans-serif"],
        "quicksand-medium": ["Quicksand-Medium", "sans-serif"],
      },
    },
  },
  plugins: [],
};
