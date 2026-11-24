const fs = require("fs");
const path = require("path");

const projectPath = path.join(__dirname, "..", "YiZhen.xcodeproj", "project.pbxproj");
const source = fs.readFileSync(projectPath, "utf8");

const declared = new Set();
const references = new Set();
const declarationByType = {};

const lines = source.split(/\r?\n/);
for (let index = 0; index < lines.length; index += 1) {
  const rawLine = lines[index];
  const declaration = rawLine.match(/(A[0-9A-F]{23})[^\n]*= \{/);
  if (declaration) {
    const typeLine = lines.slice(index, index + 3).find((line) => line.includes("isa = "));
    if (typeLine) {
      if (declared.has(declaration[1])) {
        console.log("重复声明:", declaration[1]);
      }
      declared.add(declaration[1]);
      const type = typeLine.match(/isa = ([A-Za-z]+);/);
      if (type) {
        declarationByType[type[1]] = (declarationByType[type[1]] || 0) + 1;
      }
    }
  }
  for (const reference of rawLine.matchAll(/A[0-9A-F]{23}/g)) {
    references.add(reference[0]);
  }
}

const missing = [...references].filter((identifier) => !declared.has(identifier));
const unused = [...declared].filter((identifier) => !references.has(identifier));

function section(name) {
  const start = source.indexOf(`Begin ${name} section`);
  const end = source.indexOf(`End ${name} section`);
  if (start < 0 || end < 0) return "";
  return source.slice(start, end);
}

function countEntries(name) {
  return section(name)
    .split(/\r?\n/)
    .filter((line) => line.trim().startsWith("A") && !line.includes("= {"))
    .length;
}

const braces = (source.match(/{/g) || []).length - (source.match(/}/g) || []).length;

console.log("括号平衡:", braces);
console.log("对象声明数:", declared.size);
console.log("被引用 ID 数:", references.size);
console.log("缺失声明:", missing.length, missing.slice(0, 5));
console.log("未被引用对象:", unused.length);
console.log("对象类型:", declarationByType);
console.log("Sources 条目:", countEntries("PBXSourcesBuildPhase"));
console.log("Resources 条目:", countEntries("PBXResourcesBuildPhase"));
console.log("Frameworks 条目:", countEntries("PBXFrameworksBuildPhase"));

const infoPlistPath = path.join(__dirname, "..", "YiZhen", "Resources", "Info.plist");
const infoPlist = fs.readFileSync(infoPlistPath, "utf8");
const forbiddenPlistKeys = [
  "NSMicrophoneUsageDescription",
  "NSSpeechRecognitionUsageDescription",
  "NSCameraUsageDescription",
  "NSContactsUsageDescription",
  "NSLocationWhenInUseUsageDescription",
  "NSPhotoLibraryUsageDescription",
  "NSUserTrackingUsageDescription"
];
const presentForbidden = forbiddenPlistKeys.filter((key) => infoPlist.includes(key));
console.log("Info.plist 权限键:", presentForbidden.length ? presentForbidden : "无");

const assetsDir = path.join(__dirname, "..", "YiZhen", "Resources", "Assets.xcassets");
const colorSets = fs.readdirSync(assetsDir).filter((name) => name.endsWith(".colorset"));
console.log("语义色集数量:", colorSets.length);

const swiftFiles = [];
function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full);
    else if (full.endsWith(".swift")) swiftFiles.push(full);
  }
}
walk(path.join(__dirname, "..", "YiZhen"));
const forbiddenSources = ["AVFoundation", "AVSpeechSynthesizer", "UIPasteboard", "URLSession", "UserDefaults", "tel://"];
const hits = [];
for (const file of swiftFiles) {
  const content = fs.readFileSync(file, "utf8");
  for (const token of forbiddenSources) {
    if (content.includes(token)) hits.push(`${path.basename(file)}:${token}`);
  }
}
console.log("禁用 API 引用:", hits.length ? hits : "无");
console.log("Swift 文件数:", swiftFiles.length);