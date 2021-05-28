package db

import (
	"os"
	"shorturl/utils"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGetDB(t *testing.T) {
	assert := assert.New(t)
	want := utils.RootDir() + "/tmp.db"
	defer os.Remove(utils.RootDir() + "/tmp.db")

	_, err := GetDB(utils.RootDir()+"/tmp.db", false)
	assert.FileExists(want)
	assert.NoError(err)

	got, err := GetDB("", false)
	assert.Equal(got, &Database{})
	assert.Error(err)
}

func TestDatabase_PutGetList(t *testing.T) {
	assert := assert.New(t)
	db, _ := GetDB(utils.RootDir()+"/tmp.db", false)
	defer os.Remove(utils.RootDir() + "/tmp.db")

	empty, _ := db.Get("myBucket", "key")
	assert.Equal(empty, "")

	db.Put("myBucket", "key", "value")
	got, _ := db.Get("myBucket", "key")
	assert.Equal(got, "value")

	db.Put("myBucket", "key2", "value2")
	data, _ := db.List("myBucket")
	assert.Equal(data, map[string]string{"key": "value", "key2": "value2"})
}
