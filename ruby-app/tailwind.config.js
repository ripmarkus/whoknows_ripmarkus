/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./views/**/*.erb'],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        serif: ['"DM Serif Display"', 'serif'],
      }
    }
  }
}