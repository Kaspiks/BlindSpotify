const fs = require('fs');
const path = require('path');

const includedIcons = [
  "activity",
  "alert-circle",
  "alert-triangle",
  "archive",
  "arrow-left",
  "arrow-right",
  "arrow-up",
  "arrow-down",
  "award",
  "bell",
  "bookmark",
  "calendar",
  "camera",
  "check",
  "chevron-down",
  "chevron-left",
  "chevron-right",
  "chevron-up",
  "circle-plus",
  "clock",
  "copy",
  "edit",
  "external-link",
  "eye",
  "eye-off",
  "file",
  "folder",
  "gift",
  "heart",
  "home",
  "info-circle",
  "lock",
  "login",
  "logout",
  "map",
  "map-pin",
  "menu-2",
  "message",
  "minus",
  "package",
  "photo",
  "plus",
  "search",
  "settings",
  "share",
  "shopping-cart",
  "star",
  "target",
  "trash",
  "trophy",
  "user",
  "users",
  "x",
  "category",
  "category-2",
  "list-details",
  "tag",
];

// Path to Tabler SVGs (outline style)
const tablerIconsPath = path.join(
  __dirname,
  'node_modules',
  '@tabler',
  'icons',
  'icons',
  'outline'
);

const outputPath = path.join(
  __dirname,
  '..',
  'vendor',
  'assets',
  'images',
  'icons.svg'
);

const outputDir = path.dirname(outputPath);
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

let spriteContent =
  '<svg xmlns="http://www.w3.org/2000/svg" style="display:none" class="iconset">\n';

let iconsAdded = 0;

includedIcons.forEach(iconName => {
  const iconPath = path.join(tablerIconsPath, `${iconName}.svg`);

  if (!fs.existsSync(iconPath)) {
    console.warn(`⚠ Icon not found: ${iconName}.svg`);
    return;
  }

  let iconContent = fs.readFileSync(iconPath, 'utf8');

  iconContent = iconContent
    .replace(/<svg[^>]*>/, '')
    .replace(/<\/svg>/, '');

  iconContent = iconContent
    .replace(/<path[^>]*d="M0 0h24v24H0z"[^>]*\/>/g, '');

  iconContent = iconContent
    .replace(/\s(fill|stroke)="[^"]*"/g, '')
    .replace(/\s(stroke-width)="[^"]*"/g, '')
    .replace(/\s(stroke-linecap)="[^"]*"/g, '')
    .replace(/\s(stroke-linejoin)="[^"]*"/g, '');

  spriteContent += `  <symbol id="${iconName}" viewBox="0 0 24 24">${iconContent}</symbol>\n`;
  iconsAdded++;
});

spriteContent += '</svg>\n';

fs.writeFileSync(outputPath, spriteContent, 'utf8');

console.log(`✓ Built Tabler icon sprite with ${iconsAdded} icons at ${outputPath}`);
