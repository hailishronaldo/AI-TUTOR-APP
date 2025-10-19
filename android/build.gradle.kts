allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ❌ Remove this entire block
// val newBuildDir: Directory =
//     rootProject.layout.buildDirectory
//         .dir("../../build")
//         .get()
// rootProject.layout.buildDirectory.set(newBuildDir)

// ❌ And this part too
// subprojects {
//     val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
//     project.layout.buildDirectory.set(newSubprojectBuildDir)
// }

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
