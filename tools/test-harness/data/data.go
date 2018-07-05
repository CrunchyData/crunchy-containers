package data

import (
	"database/sql"
	"fmt"

	_ "github.com/lib/pq"
)

// DB returns a pointer to a sql.DB entity.
type DB struct {
	*sql.DB
}

// Connection is a data structure that holds all the
// connection info for the database.
type Connection struct {
	DBName   string
	Host     string
	Password string
	Port     int
	SSL      string
	User     string
}

// NewDB returns a new database entity.
func (c *Connection) NewDB() (*DB, error) {
	db, err := sql.Open("postgres", c.url())
	if err != nil {
		return nil, err
	}
	if err = db.Ping(); err != nil {
		return nil, err
	}
	return &DB{db}, nil
}

// URL returns a connection string URL.
func (c *Connection) url() string {
	return fmt.Sprintf("postgres://%s:%s@%s:%d/%s?sslmode=%s",
		c.User, c.Password, c.Host, c.Port, c.DBName, c.SSL)
}

var coffees = []Coffee{
	Coffee{
		Name:    "Arusha",
		Species: "C. arabica",
		Regions: "Tanzania, Papua New Guinea",
		Comment: "either a Typica variety or a French Mission.",
	},
	Coffee{
		Name:    "Bourbon",
		Species: "C. arabica",
		Regions: "Rwanda, Latin America",
		Comment: "Around 1708 the French planted coffee on the island of Bourbon (now called Réunion) in the middle of the Indian Ocean, all probably from the same parent stock – the plant the Dutch gave them.",
	},
	Coffee{
		Name:    "Catuai",
		Species: "C. arabica",
		Regions: "Latin America",
		Comment: "This is a hybrid of Mundo Novo and Caturra bred in Brazil in the late 1940s.",
	},
	Coffee{
		Name:    "Colombian",
		Species: "C. arabica",
		Regions: "Colombia",
		Comment: "When Colombian coffee is freshly roasted it has a bright acidity, is heavy in body and is intensely aromatic.",
	},
	Coffee{
		Name:    "Ethiopian Harar",
		Species: "C. arabica",
		Regions: "Ethiopia",
		Comment: "Known for its complex, fruity flavor that resembles a dry red wine.",
	},
	Coffee{
		Name: "Ethiopian Yirgacheffe",
		Species: " 	C. arabica",
		Regions: "Ethiopia",
		Comment: "From the Yirgachefe district in the Gedeo Zone of the Southern Nations, Nationalities, and People's Region of Ethiopia.",
	},
	Coffee{
		Name:    "Geisha",
		Species: "C. arabica",
		Regions: "Ethiopia, Tanzania, Costa Rica, Panama, Colombia, Peru",
		Comment: "The most expensive varietal at coffee auctions, fetching $350.25USD in 2013.[24]",
	},
	Coffee{
		Name:    "Hawaiian Kona",
		Species: "C. arabica",
		Regions: "Hawaii",
		Comment: "Grown on the slopes of Hualalai and Mauna Loa in the Kona District on the Big Island of Hawaii. ",
	},
	Coffee{
		Name:    "Java",
		Species: "Interspecific hybrid",
		Regions: "Indonesia",
		Comment: "This coffee was once so widely traded that java became a slang term for coffee.",
	},
	Coffee{
		Name:    "Maragogipe",
		Species: "C. arabica",
		Regions: "Latin America",
		Comment: "Maragogipe is considered to be a natural mutation from Typica",
	},
	Coffee{
		Name:    "Santos",
		Species: "C. arabica",
		Regions: "Brazil",
		Comment: "The name refers to the port in Brazil where coffee passed through, and was regarded as higher quality than Brazilian coffee.",
	},
	Coffee{
		Name:    "Sulawesi",
		Species: "C. arabica",
		Regions: "Indonesia",
		Comment: "Sulawesi exhibits a rich, full body, well-balanced acidity and is multi-dimensional in character.",
	},
	Coffee{
		Name:    "Sumatra Mandheling",
		Species: "C. arabica",
		Regions: "Indonesia",
		Comment: "Mandheling is named after the Mandailing people located in North Sumatra, Indonesia.",
	},
}
