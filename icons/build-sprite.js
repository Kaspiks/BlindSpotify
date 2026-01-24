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
  "brand-spotify",
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
  "device-gamepad-2",
  "edit",
  "external-link",
  "eye",
  "eye-off",
  "file",
  "folder",
  "gift",
  "heart",
  "history",
  "home",
  "info-circle",
  "list",
  "lock",
  "login",
  "logout",
  "map",
  "map-pin",
  "menu-2",
  "message",
  "minus",
  "music",
  "music-off",
  "package",
  "photo",
  "player-pause",
  "player-play",
  "playlist",
  "plus",
  "qrcode",
  "refresh",
  "search",
  "settings",
  "share",
  "shield",
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

// Paths to Tabler SVGs
const tablerOutlinePath = path.join(
  __dirname,
  'node_modules',
  '@tabler',
  'icons',
  'icons',
  'outline'
);

const tablerFilledPath = path.join(
  __dirname,
  'node_modules',
  '@tabler',
  'icons',
  'icons',
  'filled'
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
  // Try outline first, then filled (for brand icons)
  let iconPath = path.join(tablerOutlinePath, `${iconName}.svg`);
  if (!fs.existsSync(iconPath)) {
    iconPath = path.join(tablerFilledPath, `${iconName}.svg`);
  }

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
