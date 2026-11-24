const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const appRoot = path.join(root, "YiZhen");
const projectDir = path.join(root, "YiZhen.xcodeproj");

const colorSets = {
  background: ["F2F4F8", "0B1220"],
  surface: ["FFFFFF", "121D30"],
  separator: ["EDF0F5", "223047"],
  textPrimary: ["0F1A2E", "F2F5FA"],
  textSecondary: ["475467", "B9C4D4"],
  textWeak: ["98A2B3", "7C899D"],
  accent: ["1B41C8", "6F8DFF"],
  accentFill: ["1B41C8", "2F5BE0"],
  accentSoft: ["E8EDFB", "1B2A4A"],
  accentStroke: ["D9E2F7", "2C3F63"],
  onAccent: ["FFFFFF", "FFFFFF"],
  success: ["12796B", "3DD6C0"],
  successSoft: ["E3F2EE", "10352F"],
  danger: ["D6402B", "FF7466"],
  dangerSoft: ["FDECEA", "3A1D1B"],
  dangerStroke: ["F3C4BE", "6B2B26"],
  glassTint: ["FFFFFF@0.90", "121D30@0.92"],
  dockGlassTint: ["FFFFFF@0.92", "121D30@0.94"],
  shadowColor: ["0F1A2E@0.05", "0F1A2E@0"],
  toastSurface: ["0F1A2E", "F2F5FA"],
  toastText: ["FFFFFF", "0F1A2E"],
  sceneChipIdle: ["F4F6FB", "121D30"],
  stepIdle: ["E4E9F2", "223047"],
  stepDoneLine: ["8FA8FF", "2F5BE0"],
  secondaryButtonStroke: ["D9E4F8", "223047"],
  dangerSolid: ["D6402B", "B93220"],
  pillOkText: ["0A5C50", "3DD6C0"],
  pillFailText: ["B93220", "FF7466"],
  pillOkBg: ["E3F2EE", "10352F"],
  pillFailBg: ["FDECEA", "3A1D1B"],
  blueLine: ["D9E2F7", "2C3F63"],
  greenLine: ["CFE6E1", "1E4A43"],
  sheetGrip: ["E3EAF7", "2C3F63"],
  inputSurface: ["FFFFFF", "0B1220"],
  inputStroke: ["DDE7FA", "223047"],
  sendDisabledFill: ["EEF3FF", "1B2A4A"],
  scrim: ["101418@0.32", "101418@0.40"]
};

function parseColor(value) {
  const [hex, alphaRaw] = value.split("@");
  const alpha = alphaRaw === undefined ? 1 : Number(alphaRaw);
  return {
    red: "0x" + hex.slice(0, 2).toUpperCase(),
    green: "0x" + hex.slice(2, 4).toUpperCase(),
    blue: "0x" + hex.slice(4, 6).toUpperCase(),
    alpha: alpha.toFixed(3)
  };
}

function writeAssets() {
  const assetsDir = path.join(appRoot, "Resources", "Assets.xcassets");
  fs.mkdirSync(assetsDir, { recursive: true });
  fs.writeFileSync(
    path.join(assetsDir, "Contents.json"),
    JSON.stringify({ info: { author: "xcode", version: 1 } }, null, 2) + "\n"
  );

  for (const [name, pair] of Object.entries(colorSets)) {
    const dir = path.join(assetsDir, name + ".colorset");
    fs.mkdirSync(dir, { recursive: true });
    const light = parseColor(pair[0]);
    const dark = parseColor(pair[1]);
    const contents = {
      colors: [
        {
          color: {
            "color-space": "srgb",
            components: { alpha: light.alpha, blue: light.blue, green: light.green, red: light.red }
          },
          idiom: "universal"
        },
        {
          appearances: [{ appearance: "luminosity", value: "dark" }],
          color: {
            "color-space": "srgb",
            components: { alpha: dark.alpha, blue: dark.blue, green: dark.green, red: dark.red }
          },
          idiom: "universal"
        }
      ],
      info: { author: "xcode", version: 1 }
    };
    fs.writeFileSync(path.join(dir, "Contents.json"), JSON.stringify(contents, null, 2) + "\n");
  }
}

function walk(dir) {
  const result = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name.endsWith(".xcassets")) {
        result.push(full);
      } else {
        result.push(...walk(full));
      }
    } else {
      result.push(full);
    }
  }
  return result;
}

let counter = 1;
const idCache = new Map();
function id(key) {
  if (!idCache.has(key)) {
    idCache.set(key, "A" + counter.toString(16).toUpperCase().padStart(23, "0"));
    counter += 1;
  }
  return idCache.get(key);
}

function fileType(rel) {
  if (rel.endsWith(".swift")) return "sourcecode.swift";
  if (rel.endsWith(".plist")) return "text.plist.xml";
  if (rel.endsWith(".xcassets")) return "folder.assetcatalog";
  if (rel.endsWith(".md")) return "net.daringfireball.markdown";
  return "text";
}

function buildSourceFile(rel) {
  const name = path.posix.basename(rel);
  return `\t\t${id("file:" + rel)} /* ${name} */ = {isa = PBXFileReference; lastKnownFileType = ${fileType(rel)}; path = ${name}; sourceTree = "<group>"; };\n`;
}

function generateProject(entries) {
  const rels = entries.map((full) => path.relative(appRoot, full).replace(/\\/g, "/"));
  const appSources = rels.filter((rel) => rel.endsWith(".swift") && !rel.startsWith("Tests/"));
  const unitSources = rels.filter(
    (rel) => rel.endsWith(".swift") && (rel.startsWith("Tests/YZAppStateTests/") || rel.startsWith("Tests/DialogViewModelTests/"))
  );
  const uiSources = rels.filter((rel) => rel.endsWith(".swift") && rel.startsWith("Tests/DialogUITests/"));
  const assets = rels.find((rel) => rel.endsWith(".xcassets"));
  const browsable = rels.filter((rel) => rel.endsWith(".md") || rel.endsWith(".plist"));

  const groups = new Map();
  function ensureGroup(dir) {
    if (!groups.has(dir)) groups.set(dir, { dir, files: [], children: new Set() });
    return groups.get(dir);
  }
  ensureGroup("");

  const all = [...rels];
  for (const rel of all) {
    const parts = rel.split("/");
    let dir = "";
    for (let i = 0; i < parts.length - 1; i += 1) {
      const parent = dir;
      dir = dir === "" ? parts[i] : dir + "/" + parts[i];
      ensureGroup(dir);
      ensureGroup(parent).children.add(dir);
    }
    ensureGroup(dir).files.push(rel);
  }

  const appProduct = id("product:app");
  const unitProduct = id("product:unit");
  const uiProduct = id("product:ui");
  const projectId = id("project");
  const appTarget = id("target:app");
  const unitTarget = id("target:unit");
  const uiTarget = id("target:ui");
  const productsGroup = id("group:Products");
  const mainGroup = id("group:main");

  const buildFile = (target, rel) => `${id("build:" + target + ":" + rel)} /* ${path.posix.basename(rel)} in Sources */ = {isa = PBXBuildFile; fileRef = ${id("file:" + rel)}; };`;
  const assetBuildFile = `${id("build:app:" + assets)} /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = ${id("file:" + assets)}; };`;

  const appSourcesPhase = id("phase:app:sources");
  const appResourcesPhase = id("phase:app:resources");
  const appFrameworksPhase = id("phase:app:frameworks");
  const unitSourcesPhase = id("phase:unit:sources");
  const unitFrameworksPhase = id("phase:unit:frameworks");
  const unitResourcesPhase = id("phase:unit:resources");
  const uiSourcesPhase = id("phase:ui:sources");
  const uiFrameworksPhase = id("phase:ui:frameworks");
  const uiResourcesPhase = id("phase:ui:resources");

  const list = (items) => items.map((item) => `\t\t\t\t${item},`).join("\n");

  let phases = "";
  phases += `\t\t${appFrameworksPhase} /* Frameworks */ = {\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n`;
  phases += `\t\t${unitFrameworksPhase} /* Frameworks */ = {\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n`;
  phases += `\t\t${uiFrameworksPhase} /* Frameworks */ = {\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n`;

  const dependencies = `\t\t${id("dep:unit")} /* PBXTargetDependency */ = {\n\t\t\tisa = PBXTargetDependency;\n\t\t\ttarget = ${appTarget} /* YiZhen */;\n\t\t\ttargetProxy = ${id("proxy:unit")} /* PBXContainerItemProxy */;\n\t\t};\n\t\t${id("dep:ui")} /* PBXTargetDependency */ = {\n\t\t\tisa = PBXTargetDependency;\n\t\t\ttarget = ${appTarget} /* YiZhen */;\n\t\t\ttargetProxy = ${id("proxy:ui")} /* PBXContainerItemProxy */;\n\t\t};\n`;
  const proxies = `\t\t${id("proxy:unit")} /* PBXContainerItemProxy */ = {\n\t\t\tisa = PBXContainerItemProxy;\n\t\t\tcontainerPortal = ${projectId} /* Project object */;\n\t\t\tproxyType = 1;\n\t\t\tremoteGlobalIDString = ${appTarget};\n\t\t\tremoteInfo = YiZhen;\n\t\t};\n\t\t${id("proxy:ui")} /* PBXContainerItemProxy */ = {\n\t\t\tisa = PBXContainerItemProxy;\n\t\t\tcontainerPortal = ${projectId} /* Project object */;\n\t\t\tproxyType = 1;\n\t\t\tremoteGlobalIDString = ${appTarget};\n\t\t\tremoteInfo = YiZhen;\n\t\t};\n`;

  const targets = `\t\t${appTarget} /* YiZhen */ = {\n\t\t\tisa = PBXNativeTarget;\n\t\t\tbuildConfigurationList = ${id("configlist:app")};\n\t\t\tbuildPhases = (\n\t\t\t\t${appSourcesPhase} /* Sources */,\n\t\t\t\t${appFrameworksPhase} /* Frameworks */,\n\t\t\t\t${appResourcesPhase} /* Resources */,\n\t\t\t);\n\t\t\tbuildRules = (\n\t\t\t);\n\t\t\tdependencies = (\n\t\t\t);\n\t\t\tname = YiZhen;\n\t\t\tproductName = YiZhen;\n\t\t\tproductReference = ${appProduct} /* YiZhen.app */;\n\t\t\tproductType = "com.apple.product-type.application";\n\t\t};\n\t\t${unitTarget} /* YiZhenTests */ = {\n\t\t\tisa = PBXNativeTarget;\n\t\t\tbuildConfigurationList = ${id("configlist:unit")};\n\t\t\tbuildPhases = (\n\t\t\t\t${unitSourcesPhase} /* Sources */,\n\t\t\t\t${unitFrameworksPhase} /* Frameworks */,\n\t\t\t\t${unitResourcesPhase} /* Resources */,\n\t\t\t);\n\t\t\tbuildRules = (\n\t\t\t);\n\t\t\tdependencies = (\n\t\t\t\t${id("dep:unit")} /* PBXTargetDependency */,\n\t\t\t);\n\t\t\tname = YiZhenTests;\n\t\t\tproductName = YiZhenTests;\n\t\t\tproductReference = ${unitProduct} /* YiZhenTests.xctest */;\n\t\t\tproductType = "com.apple.product-type.bundle.unit-test";\n\t\t};\n\t\t${uiTarget} /* YiZhenUITests */ = {\n\t\t\tisa = PBXNativeTarget;\n\t\t\tbuildConfigurationList = ${id("configlist:ui")};\n\t\t\tbuildPhases = (\n\t\t\t\t${uiSourcesPhase} /* Sources */,\n\t\t\t\t${uiFrameworksPhase} /* Frameworks */,\n\t\t\t\t${uiResourcesPhase} /* Resources */,\n\t\t\t);\n\t\t\tbuildRules = (\n\t\t\t);\n\t\t\tdependencies = (\n\t\t\t\t${id("dep:ui")} /* PBXTargetDependency */,\n\t\t\t);\n\t\t\tname = YiZhenUITests;\n\t\t\tproductName = YiZhenUITests;\n\t\t\tproductReference = ${uiProduct} /* YiZhenUITests.xctest */;\n\t\t\tproductType = "com.apple.product-type.bundle.ui-testing";\n\t\t};\n`;

  const project = `\t\t${projectId} /* Project object */ = {\n\t\t\tisa = PBXProject;\n\t\t\tattributes = {\n\t\t\t\tBuildIndependentTargetsInParallel = 1;\n\t\t\t\tLastSwiftUpdateCheck = 1600;\n\t\t\t\tLastUpgradeCheck = 1600;\n\t\t\t\tTargetAttributes = {\n\t\t\t\t\t${appTarget} = {\n\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;\n\t\t\t\t\t};\n\t\t\t\t\t${unitTarget} = {\n\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;\n\t\t\t\t\t\tTestTargetID = ${appTarget};\n\t\t\t\t\t};\n\t\t\t\t\t${uiTarget} = {\n\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;\n\t\t\t\t\t\tTestTargetID = ${appTarget};\n\t\t\t\t\t};\n\t\t\t\t};\n\t\t\t};\n\t\t\tbuildConfigurationList = ${id("configlist:project")};\n\t\t\tcompatibilityVersion = "Xcode 14.0";\n\t\t\tdevelopmentRegion = "zh-Hans";\n\t\t\thasScannedForEncodings = 0;\n\t\t\tknownRegions = (\n\t\t\t\ten,\n\t\t\t\tBase,\n\t\t\t\t"zh-Hans",\n\t\t\t);\n\t\t\tmainGroup = ${mainGroup};\n\t\t\tproductRefGroup = ${productsGroup} /* Products */;\n\t\t\tprojectDirPath = "";\n\t\t\tprojectRoot = "";\n\t\t\ttargets = (\n\t\t\t\t${appTarget} /* YiZhen */,\n\t\t\t\t${unitTarget} /* YiZhenTests */,\n\t\t\t\t${uiTarget} /* YiZhenUITests */,\n\t\t\t);\n\t\t};\n`;

  const fileRefs = rels.filter((rel) => rel !== assets).map(buildSourceFile).join("");
  const assetsRef = assets
    ? `\t\t${id("file:" + assets)} /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };\n`
    : "";
  const productRefs = `\t\t${appProduct} /* YiZhen.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = YiZhen.app; sourceTree = BUILT_PRODUCTS_DIR; };\n\t\t${unitProduct} /* YiZhenTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = YiZhenTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };\n\t\t${uiProduct} /* YiZhenUITests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = YiZhenUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };\n`;

  const groupEntries = [];
  const groupOrder = Array.from(groups.keys()).sort((a, b) => {
    const da = a === "" ? 0 : a.split("/").length;
    const db = b === "" ? 0 : b.split("/").length;
    return db - da;
  });
  for (const dir of groupOrder) {
    const group = groups.get(dir);
    const name = dir === "" ? "YiZhen" : path.posix.basename(dir);
    const childIds = Array.from(group.children)
      .sort()
      .map((child) => `${id("group:" + child)} /* ${path.posix.basename(child)} */`);
    const fileIds = group.files
      .sort()
      .map((rel) => `${id("file:" + rel)} /* ${path.posix.basename(rel)} */`);
    const children = [...childIds, ...fileIds];
    const groupPath = dir === "" ? "YiZhen" : name;
    groupEntries.push(
      `\t\t${id("group:" + dir)} /* ${name} */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n${children.map((child) => `\t\t\t\t${child},`).join("\n")}\n\t\t\t);\n\t\t\tpath = ${groupPath};\n\t\t\tsourceTree = "<group>";\n\t\t};\n`
    );
  }
  const productsEntry = `\t\t${productsGroup} /* Products */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t${appProduct} /* YiZhen.app */,\n\t\t\t\t${unitProduct} /* YiZhenTests.xctest */,\n\t\t\t\t${uiProduct} /* YiZhenUITests.xctest */,\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = "<group>";\n\t\t};\n`;
  const mainEntry = `\t\t${mainGroup} = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t${id("group:")} /* YiZhen */,\n\t\t\t\t${productsGroup} /* Products */,\n\t\t\t);\n\t\t\tsourceTree = "<group>";\n\t\t};\n`;

  const projectDebug = `\t\t${id("config:project:debug")} /* Debug */ = {\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {\n\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;\n\t\t\t\tCLANG_ANALYZER_NONNULL = YES;\n\t\t\t\tCLANG_ENABLE_MODULES = YES;\n\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;\n\t\t\t\tCOPY_PHASE_STRIP = NO;\n\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;\n\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;\n\t\t\t\tENABLE_TESTABILITY = YES;\n\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;\n\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;\n\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;\n\t\t\t\tONLY_ACTIVE_ARCH = YES;\n\t\t\t\tSDKROOT = iphoneos;\n\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";\n\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";\n\t\t\t\tSWIFT_VERSION = 5.0;\n\t\t\t};\n\t\t\tname = Debug;\n\t\t};\n`;
  const projectRelease = `\t\t${id("config:project:release")} /* Release */ = {\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {\n\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;\n\t\t\t\tCLANG_ANALYZER_NONNULL = YES;\n\t\t\t\tCLANG_ENABLE_MODULES = YES;\n\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;\n\t\t\t\tCOPY_PHASE_STRIP = NO;\n\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";\n\t\t\t\tENABLE_NS_ASSERTIONS = NO;\n\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;\n\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;\n\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;\n\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;\n\t\t\t\tSDKROOT = iphoneos;\n\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;\n\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";\n\t\t\t\tSWIFT_VERSION = 5.0;\n\t\t\t\tVALIDATE_PRODUCT = YES;\n\t\t\t};\n\t\t\tname = Release;\n\t\t};\n`;

  const appSettings = `\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;\n\t\t\t\tCODE_SIGN_STYLE = Automatic;\n\t\t\t\tCURRENT_PROJECT_VERSION = 1;\n\t\t\t\tENABLE_PREVIEWS = YES;\n\t\t\t\tGENERATE_INFOPLIST_FILE = NO;\n\t\t\t\tINFOPLIST_FILE = YiZhen/Resources/Info.plist;\n\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"@executable_path/Frameworks",\n\t\t\t\t);\n\t\t\t\tMARKETING_VERSION = 1.0;\n\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.yizhen.app;\n\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";\n\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;\n\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";\n`;
  const unitSettings = `\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";\n\t\t\t\tCODE_SIGN_STYLE = Automatic;\n\t\t\t\tCURRENT_PROJECT_VERSION = 1;\n\t\t\t\tENABLE_TESTING_SEARCH_PATHS = YES;\n\t\t\t\tGENERATE_INFOPLIST_FILE = YES;\n\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"@executable_path/Frameworks",\n\t\t\t\t\t"@loader_path/Frameworks",\n\t\t\t\t);\n\t\t\t\tMARKETING_VERSION = 1.0;\n\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.yizhen.app.tests;\n\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";\n\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;\n\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";\n\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/YiZhen.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/YiZhen";\n`;
  const uiSettings = `\t\t\t\tCODE_SIGN_STYLE = Automatic;\n\t\t\t\tCURRENT_PROJECT_VERSION = 1;\n\t\t\t\tENABLE_TESTING_SEARCH_PATHS = YES;\n\t\t\t\tGENERATE_INFOPLIST_FILE = YES;\n\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"@executable_path/Frameworks",\n\t\t\t\t\t"@loader_path/Frameworks",\n\t\t\t\t);\n\t\t\t\tMARKETING_VERSION = 1.0;\n\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.yizhen.app.uitests;\n\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";\n\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;\n\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";\n\t\t\t\tTEST_TARGET_NAME = YiZhen;\n`;

  const targetConfigs = `\t\t${id("config:app:debug")} /* Debug */ = {\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {\n${appSettings}\t\t\t};\n\t\t\tname = Debug;\n\t\t};\n\t\t${id("config:app:release")} /* Release */ = {\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {\n${appSettings}\t\t\t};\n\t\t\tname = Release;\n\t\t};\n\t\t${id("config:unit:debug")} /* Debug */ = {\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {\n${unitSettings}\t\t\t};\n\t\t\tname = Debug;\n\t\t};\n\t\t${id("config:unit:release")} /* Release */ = {\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {\n${unitSettings}\t\t\t};\n\t\t\tname = Release;\n\t\t};\n\t\t${id("config:ui:debug")} /* Debug */ = {\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {\n${uiSettings}\t\t\t};\n\t\t\tname = Debug;\n\t\t};\n\t\t${id("config:ui:release")} /* Release */ = {\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {\n${uiSettings}\t\t\t};\n\t\t\tname = Release;\n\t\t};\n`;

  const configLists = `\t\t${id("configlist:project")} = {\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n\t\t\t\t${id("config:project:debug")} /* Debug */,\n\t\t\t\t${id("config:project:release")} /* Release */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t};\n\t\t${id("configlist:app")} = {\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n\t\t\t\t${id("config:app:debug")} /* Debug */,\n\t\t\t\t${id("config:app:release")} /* Release */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t};\n\t\t${id("configlist:unit")} = {\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n\t\t\t\t${id("config:unit:debug")} /* Debug */,\n\t\t\t\t${id("config:unit:release")} /* Release */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t};\n\t\t${id("configlist:ui")} = {\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n\t\t\t\t${id("config:ui:debug")} /* Debug */,\n\t\t\t\t${id("config:ui:release")} /* Release */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t};\n`;

  const content = `// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 56;\n\tobjects = {\n\n/* Begin PBXBuildFile section */\n${[...appSources.map((rel) => buildFile("app", rel)), ...unitSources.map((rel) => buildFile("unit", rel)), ...uiSources.map((rel) => buildFile("ui", rel)), assetBuildFile].join("\n")}\n/* End PBXBuildFile section */\n\n/* Begin PBXContainerItemProxy section */\n${proxies}/* End PBXContainerItemProxy section */\n\n/* Begin PBXFileReference section */\n${fileRefs}${assetsRef}${productRefs}/* End PBXFileReference section */\n\n/* Begin PBXFrameworksBuildPhase section */\n${phases}\n/* End PBXFrameworksBuildPhase section */\n\n/* Begin PBXGroup section */\n${groupEntries.join("\n")}\n${productsEntry}\n${mainEntry}\n/* End PBXGroup section */\n\n/* Begin PBXNativeTarget section */\n${targets}\n/* End PBXNativeTarget section */\n\n/* Begin PBXProject section */\n${project}\n/* End PBXProject section */\n\n/* Begin PBXResourcesBuildPhase section */\n\t\t${appResourcesPhase} /* Resources */ = {\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t\t${assetBuildFile.split(" = ")[0]},\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n\t\t${unitResourcesPhase} /* Resources */ = {\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n\t\t${uiResourcesPhase} /* Resources */ = {\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n/* End PBXResourcesBuildPhase section */\n\n/* Begin PBXSourcesBuildPhase section */\n\t\t${appSourcesPhase} /* Sources */ = {\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n${list(appSources.map((rel) => id("build:app:" + rel)))}\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n\t\t${unitSourcesPhase} /* Sources */ = {\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n${list(unitSources.map((rel) => id("build:unit:" + rel)))}\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n\t\t${uiSourcesPhase} /* Sources */ = {\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n${list(uiSources.map((rel) => id("build:ui:" + rel)))}\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n/* End PBXSourcesBuildPhase section */\n\n/* Begin PBXTargetDependency section */\n${dependencies}/* End PBXTargetDependency section */\n\n/* Begin XCBuildConfiguration section */\n${projectDebug}${projectRelease}${targetConfigs}/* End XCBuildConfiguration section */\n\n/* Begin XCConfigurationList section */\n${configLists}/* End XCConfigurationList section */\n\t};\n\trootObject = ${projectId} /* Project object */;\n}\n`;

  fs.mkdirSync(projectDir, { recursive: true });
  fs.writeFileSync(path.join(projectDir, "project.pbxproj"), content);

  const schemeDir = path.join(projectDir, "xcshareddata", "xcschemes");
  fs.mkdirSync(schemeDir, { recursive: true });
  const scheme = `<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "1600" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "${appTarget}" BuildableName = "YiZhen.app" BlueprintName = "YiZhen" ReferencedContainer = "container:YiZhen.xcodeproj"/>
         </BuildActionEntry>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "NO" buildForProfiling = "NO" buildForArchiving = "NO" buildForAnalyzing = "NO">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "${unitTarget}" BuildableName = "YiZhenTests.xctest" BlueprintName = "YiZhenTests" ReferencedContainer = "container:YiZhen.xcodeproj"/>
         </BuildActionEntry>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "NO" buildForProfiling = "NO" buildForArchiving = "NO" buildForAnalyzing = "NO">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "${uiTarget}" BuildableName = "YiZhenUITests.xctest" BlueprintName = "YiZhenUITests" ReferencedContainer = "container:YiZhen.xcodeproj"/>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference skipped = "NO">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "${unitTarget}" BuildableName = "YiZhenTests.xctest" BlueprintName = "YiZhenTests" ReferencedContainer = "container:YiZhen.xcodeproj"/>
         </TestableReference>
         <TestableReference skipped = "NO">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "${uiTarget}" BuildableName = "YiZhenUITests.xctest" BlueprintName = "YiZhenUITests" ReferencedContainer = "container:YiZhen.xcodeproj"/>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "${appTarget}" BuildableName = "YiZhen.app" BlueprintName = "YiZhen" ReferencedContainer = "container:YiZhen.xcodeproj"/>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES" savedToolIdentifier = "" useCustomWorkingDirectory = "NO" debugDocumentVersioning = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "${appTarget}" BuildableName = "YiZhen.app" BlueprintName = "YiZhen" ReferencedContainer = "container:YiZhen.xcodeproj"/>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug"/>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES"/>
</Scheme>
`;
  fs.writeFileSync(path.join(schemeDir, "YiZhen.xcscheme"), scheme);
}

writeAssets();
const entries = walk(appRoot);
generateProject(entries);
console.log("generated:", path.join(projectDir, "project.pbxproj"));
console.log("app swift:", entries.filter((f) => f.endsWith(".swift") && !f.includes(path.sep + "Tests" + path.sep)).length);
console.log("unit test swift:", entries.filter((f) => f.endsWith(".swift") && (f.includes(path.sep + "YZAppStateTests" + path.sep) || f.includes(path.sep + "DialogViewModelTests" + path.sep))).length);
console.log("ui test swift:", entries.filter((f) => f.endsWith(".swift") && f.includes(path.sep + "DialogUITests" + path.sep)).length);