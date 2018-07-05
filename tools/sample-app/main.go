package main

import (
	"log"
	"net/http"
	"time"
    "os"
	"github.com/gorilla/mux"
	pg "github.com/crunchydata/crunchy-containers/tools/sample-app/data"
)

func init() {
	log.SetOutput(os.Stdout)
}

func main() {
	connURL := pg.ConnURL{
		DBName:   dbName,
		Host:     host,
		Password: password,
		SSL:      "disable",
		User:     user,
		Port:     port,
	}

	db, err := pg.NewDB(connURL.URL())
	if err != nil {
		log.Fatalf("Error connecting to database: %v", err)
	}
	defer db.Close()

	r := mux.NewRouter()
	r.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		var results struct {
			CRUD       []pg.CRUDResult
			DB         []pg.Database
			Extensions []pg.Extension
			Roles      []pg.Role
			Settings   []pg.Setting
		}

		results.CRUD = db.RunCRUD()
		results.DB, err = db.Databases()
		results.Extensions, err = db.InstalledExtensions()
		results.Roles, err = db.Roles()
		results.Settings, err = db.Settings()

		if err != nil {
			log.Fatalf("Could not parse databases: %s", err)
		}
		err = tmpl.Execute(w, results)
		if err != nil {
			log.Fatalf("Could not execute template: %s", err)
		}
	})
	r.PathPrefix("/").Handler(http.FileServer(http.Dir("/tmp/static/")))
	http.Handle("/", r)

	srv := &http.Server{
		Handler:      r,
		Addr:         ":8000",
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}

	log.Fatal(srv.ListenAndServe())
}
