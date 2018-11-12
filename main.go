package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"path"
	"time"
)

var version = "0.0.0"
var makefilePath = "/test/Makefilea"

func getWorkingDirectory() string {
	cwd, err := os.Getwd()
	if err != nil {
		panic(err)
	}
	return cwd
}

func openMakefile(pathToMakefile string) string {
	file, err := os.Open(pathToMakefile)
	if err != nil {
		if os.IsNotExist(err) {
			fmt.Println("OK")
		} else {
			panic(err)
		}
	}
	defer file.Close()
	fileInfo, _ := file.Stat()
	fileContents := make([]byte, fileInfo.Size())
	file.Read(fileContents)
	return string(fileContents)
}

func makefileExists(pathToMakefile string) bool {
	if _, err := os.Stat(pathToMakefile); os.IsNotExist(err) {
		return false
	}
	return true
}

func createFile(pathToMakefile string) *os.File {
	fmt.Println(" - Creating Makefile at " + pathToMakefile + "...")
	defer fmt.Println(" - Makefile created at " + pathToMakefile)
	file, err := os.Create(pathToMakefile)
	if err != nil {
		panic(err)
	}
	return file
}

func downloadMakefile(versionNumber string) string {
	fileURL := getMakefileURL(versionNumber)
	fmt.Println(" - Downloading Makefile from " + fileURL + "...")
	_res, err := http.Get(fileURL)
	if err != nil {
		panic(err)
	}
	defer _res.Body.Close()
	res, err := ioutil.ReadAll(_res.Body)
	if err != nil {
		panic(err)
	}
	return string(res)
}

func getMakefileHandle(pathToMakefile string) *os.File {
	if makefileExists(pathToMakefile) {
		fmt.Println(" - Makefile already exists, creating backup...")
		backup := createFile(pathToMakefile + "." + time.Now().Format("20060102150405"))
		defer backup.Close()
		file, err := os.Open(pathToMakefile)
		defer file.Close()
		if err != nil {
			panic(err)
		}
		io.Copy(backup, file)
	} else {
		fmt.Println(" - Makefile doesn't already exist.")
	}
	return createFile(pathToMakefile)
}

func main() {
	printLogo(version)
	workingDirectory := getWorkingDirectory()
	fmt.Println(" - initializing Makefile at " + workingDirectory + "...")
	absoluteMakefilePath := path.Join(workingDirectory, makefilePath)
	fmt.Println(" - Makefile path = " + absoluteMakefilePath)
	makefile := getMakefileHandle(absoluteMakefilePath)
	defer makefile.Close()
	updatedMakefileContent := downloadMakefile(version)
	if _, err := makefile.Write([]byte(updatedMakefileContent)); err != nil {
		panic(err)
	}
}

func getMakefileURL(versionNumber string) string {
	return "https://raw.githubusercontent.com/zephinzer/goinit/" + versionNumber + "/Makefile"
}

func printLogo(versionNumber string) {
	fmt.Println("$$$$$$\\            $$$$$$\\           $$\\   $$\\      ")
	fmt.Println("$$  __$$\\           \\_$$  _|          \\__|  $$ |    ")
	fmt.Println("$$ /  \\__| $$$$$$\\    $$ |  $$$$$$$\\  $$\\ $$$$$$\\   ")
	fmt.Println("$$ |$$$$\\ $$  __$$\\   $$ |  $$  __$$\\ $$ |\\_$$  _|  ")
	fmt.Println("$$ |\\_$$ |$$ /  $$ |  $$ |  $$ |  $$ |$$ |  $$ |    ")
	fmt.Println("$$ |  $$ |$$ |  $$ |  $$ |  $$ |  $$ |$$ |  $$ |$$\\ ")
	fmt.Println("\\$$$$$$  |\\$$$$$$  |$$$$$$\\ $$ |  $$ |$$ |  \\$$$$  |")
	fmt.Println(" \\______/  \\______/ \\______|\\__|  \\__|\\__|   \\____/ ")
	fmt.Println(" - version " + versionNumber)
}
