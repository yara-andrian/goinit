package main

import (
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"path"
	"time"
)

const makefileURL = "https://raw.githubusercontent.com/zephinzer/goinit/master/Makefile"

func main() {
	workingDirectory := getWorkingDirectory()
	makefileContents := retrieveRemoteMakefile()
	makefilePath := path.Join(workingDirectory, "./Makefile")
	if fileExists(makefilePath) == true {
		backupFile(makefilePath)
	}
	makefileHandle := createFile(makefilePath)
	makefileHandle.Write([]byte(makefileContents))
}

func backupFile(filePath string) {
	backup := createFile(filePath + "." + time.Now().Format("20060102150405"))
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
