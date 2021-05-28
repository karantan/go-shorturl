package db

import (
	"shorturl/logger"
	"time"

	bolt "go.etcd.io/bbolt"
)

var log = logger.New("db", false)

type Database struct {
	db *bolt.DB
}

type Databaser interface {
	Get(string, string) (string, error)
	Put(string, string, string) error
	List(string) (map[string]string, error)
	Close()
}

func (b *Database) Close() {
	b.db.Close()
}

func GetDB(filename string, readonly bool) (Databaser, error) {
	db, err := bolt.Open(filename, 0600, &bolt.Options{Timeout: 1 * time.Second, ReadOnly: readonly})
	if err != nil {
		return &Database{}, err
	}
	return &Database{db}, nil
}

func (b *Database) Get(bucket, key string) (data string, err error) {
	b.db.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(bucket))
		if b == nil {
			log.Warnf("Bucket %v doesn't exist!", bucket)
			return nil
		}
		v := b.Get([]byte(key))
		data = string(v)
		return nil
	})
	return
}

func (b *Database) Put(bucket, key, value string) error {
	return b.db.Update(func(tx *bolt.Tx) error {
		b, err := tx.CreateBucketIfNotExists([]byte(bucket))
		if err != nil {
			return err
		}
		err = b.Put([]byte(key), []byte(value))
		return err
	})
}

func (b *Database) List(bucket string) (map[string]string, error) {
	data := make(map[string]string)
	err := b.db.View(func(tx *bolt.Tx) error {
		// Assume bucket exists and has keys
		b := tx.Bucket([]byte(bucket))
		if b == nil {
			log.Warnf("Bucket %v doesn't exist!", bucket)
			return nil
		}

		return b.ForEach(func(k, v []byte) error {
			data[string(k)] = string(v)
			return nil
		})
	})
	return data, err
}
