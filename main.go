package main

import (
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"path"
	"strconv"
	"time"
)

const makefileURL = "https://raw.githubusercontent.com/zephinzer/goinit/master/Makefile"
const version = "0.3.1"

func main() {
	versionFlag := flag.Bool("v", false, "prints current version")
	flag.Parse()
	if *versionFlag {
		fmt.Println(version)
		os.Exit(0)
	}

	printLogo()

	workingDirectory := getWorkingDirectory()
	fmt.Println(" - initialising a Golang project at " + workingDirectory)

	fmt.Println(" - downloading latest Makefile...")
	makefileContents := retrieveRemoteMakefile()
	fmt.Println(" - downloaded latest Makefile")

	makefilePath := path.Join(workingDirectory, "./Makefile")
	if fileExists(makefilePath) == true {
		backupFilePath := makefilePath + "." + time.Now().Format("20060102150405")
		fmt.Println(" - Makefile found, making a backup now at " + backupFilePath)
		backupFile(makefilePath, backupFilePath)
		fmt.Println(" - Makefile backup created")
	}

	fmt.Println(" - writing latest Makefile to " + makefilePath)
	makefileHandle := createFile(makefilePath)
	fileSize := writeToFile(makefileHandle, []byte(makefileContents))
	fmt.Println(" - wrote " + strconv.Itoa(fileSize) + " bytes")

	fmt.Println(" - run `make init` to get started!")
}

func backupFile(filePath string, backupFilePath string) {
	backup := createFile(backupFilePath)
	defer backup.Close()
	file, err := os.Open(filePath)
	defer file.Close()
	if err != nil {
		panic(err)
	}
	io.Copy(backup, file)
}

func createFile(filePath string) *os.File {
	file, err := os.Create(filePath)
	if err != nil {
		panic(err)
	}
	return file
}
func writeToFile(file *os.File, data []byte) int {
	fileSize, err := file.Write(data)
	if err != nil {
		panic(err)
	}
	return fileSize
}

func fileExists(filePath string) bool {
	_, err := os.Stat(filePath)
	if os.IsNotExist(err) {
		return false
	}
	return true
}

func getWorkingDirectory() string {
	workingDirectory, err := os.Getwd()
	if err != nil {
		panic(err)
	}
	return workingDirectory
}

func printLogo() {
	fmt.Println("$$$$$$\\            $$$$$$\\           $$\\   $$\\      ")
	fmt.Println("$$  __$$\\           \\_$$  _|          \\__|  $$ |    ")
	fmt.Println("$$ /  \\__| $$$$$$\\    $$ |  $$$$$$$\\  $$\\ $$$$$$\\   ")
	fmt.Println("$$ |$$$$\\ $$  __$$\\   $$ |  $$  __$$\\ $$ |\\_$$  _|  ")
	fmt.Println("$$ |\\_$$ |$$ /  $$ |  $$ |  $$ |  $$ |$$ |  $$ |    ")
	fmt.Println("$$ |  $$ |$$ |  $$ |  $$ |  $$ |  $$ |$$ |  $$ |$$\\ ")
	fmt.Println("\\$$$$$$  |\\$$$$$$  |$$$$$$\\ $$ |  $$ |$$ |  \\$$$$  |")
	fmt.Println(" \\______/  \\______/ \\______|\\__|  \\__|\\__|   \\____/ ")
}

func retrieveRemoteMakefile() string {
	_response, err := http.Get(makefileURL)
	if err != nil {
		panic(err)
	}
	defer _response.Body.Close()
	response, err := ioutil.ReadAll(_response.Body)
	responseString := string(response)
	return responseString
}
