docker build `
-t powershellbuildkit:latest `
--build-arg PowerShellContainerTag=alpine-3.17 `
--build-arg apkPackageJSON="['npm', 'nodejs']" `
--build-arg DevContainerFeatureJSON="{'repository':'https://github.com/devcontainers/features','sparse':'src/common-utils'}" `
--build-arg InvokeExpressionJSON="[ 'npm install -g @vscode/vsce' ]" `
--build-arg InstallModuleJSON="{ 'ModuleName': 'Pode', 'RequiredVersion': '2.8.0' }" `
.