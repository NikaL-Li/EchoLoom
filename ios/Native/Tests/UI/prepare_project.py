"""Generate a disposable UI-test project beside the real one. No production project edits."""
from pathlib import Path
import plistlib, subprocess, uuid
root=Path(__file__).resolve().parents[2]
p=root/'译声.xcodeproj/project.pbxproj'
d=plistlib.loads(subprocess.check_output(['plutil','-convert','xml1','-o','-',str(p)])); o=d['objects']; project=o[d['rootObject']]
def add(value):
 key=uuid.uuid4().hex[:24].upper(); o[key]=value; return key
app_id=next(k for k,v in o.items() if v['isa']=='PBXNativeTarget' and v['name']=='译声')
source=add(dict(isa='PBXFileReference',lastKnownFileType='sourcecode.swift',path='Tests/UI/ConversationUITests.swift',sourceTree='SOURCE_ROOT'))
o[project['mainGroup']]['children'].append(source)
product=add(dict(isa='PBXFileReference',explicitFileType='wrapper.cfbundle',path='ConversationUITests.xctest',sourceTree='BUILT_PRODUCTS_DIR'))
o[project['productRefGroup']]['children'].append(product)
build=add(dict(isa='PBXBuildFile',fileRef=source))
phases=[add(dict(isa='PBXSourcesBuildPhase',buildActionMask='2147483647',files=[build],runOnlyForDeploymentPostprocessing='0')),add(dict(isa='PBXFrameworksBuildPhase',buildActionMask='2147483647',files=[],runOnlyForDeploymentPostprocessing='0')),add(dict(isa='PBXResourcesBuildPhase',buildActionMask='2147483647',files=[],runOnlyForDeploymentPostprocessing='0'))]
configs=[]
for name in ['Debug','Release']:
 configs.append(add(dict(isa='XCBuildConfiguration',name=name,buildSettings=dict(PRODUCT_NAME='$(TARGET_NAME)',PRODUCT_BUNDLE_IDENTIFIER='com.ylct.ConversationUITests',SWIFT_VERSION='5.0',IPHONEOS_DEPLOYMENT_TARGET='18.2',SDKROOT='iphoneos',TARGETED_DEVICE_FAMILY='1',GENERATE_INFOPLIST_FILE='YES',TEST_TARGET_NAME='译声',CODE_SIGN_STYLE='Automatic',SWIFT_OPTIMIZATION_LEVEL='-Onone'))))
config=add(dict(isa='XCConfigurationList',buildConfigurations=configs,defaultConfigurationIsVisible='0',defaultConfigurationName='Debug'))
proxy=add(dict(isa='PBXContainerItemProxy',containerPortal=d['rootObject'],proxyType='1',remoteGlobalIDString=app_id,remoteInfo='译声'))
dep=add(dict(isa='PBXTargetDependency',target=app_id,targetProxy=proxy))
target=add(dict(isa='PBXNativeTarget',name='ConversationUITests',productName='ConversationUITests',productReference=product,productType='com.apple.product-type.bundle.ui-testing',buildConfigurationList=config,buildPhases=phases,buildRules=[],dependencies=[dep]))
project['targets'].append(target)
folder=root/'UITesting.xcodeproj'; folder.mkdir(exist_ok=True)
(folder/'project.pbxproj').write_bytes(plistlib.dumps(d))
scheme=folder/'xcshareddata/xcschemes'; scheme.mkdir(parents=True,exist_ok=True)
def ref(id,name,product): return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{id}" BuildableName="{product}" BlueprintName="{name}" ReferencedContainer="container:UITesting.xcodeproj"/>'
(scheme/'ConversationChecks.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref(app_id,'译声','译声.app')}</BuildActionEntry></BuildActionEntries></BuildAction><TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{ref(target,'ConversationUITests','ConversationUITests.xctest')}</TestableReference></Testables></TestAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0"><BuildableProductRunnable runnableDebuggingMode="0">{ref(app_id,'译声','译声.app')}</BuildableProductRunnable></LaunchAction></Scheme>''')
print(folder)
