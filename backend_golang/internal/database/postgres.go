package database

import (
	"log"
	"time"

	"aureader/backend/config"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

// Connect initialises a GORM connection pool to PostgreSQL and stores it in DB.
func Connect(cfg *config.Config) *gorm.DB {
	logLevel := logger.Silent
	if !cfg.IsProduction() {
		logLevel = logger.Info
	}

	gormLogger := logger.New(
		log.New(log.Writer(), "\r\n", log.LstdFlags),
		logger.Config{
			SlowThreshold:             200 * time.Millisecond,
			LogLevel:                  logLevel,
			IgnoreRecordNotFoundError: true,
			Colorful:                  !cfg.IsProduction(),
		},
	)

	db, err := gorm.Open(postgres.New(postgres.Config{
		DSN:                  cfg.DBDsn(),
		PreferSimpleProtocol: true, // disables implicit prepared statement usage
	}), &gorm.Config{
		Logger:                                   gormLogger,
		DisableForeignKeyConstraintWhenMigrating: true,
		TranslateError:                           true, // map driver errors to gorm.ErrDuplicatedKey etc.
	})
	if err != nil {
		log.Fatalf("[DB] Failed to connect to PostgreSQL: %v", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("[DB] Failed to get underlying sql.DB: %v", err)
	}

	// Connection pool settings
	sqlDB.SetMaxOpenConns(25)
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetConnMaxLifetime(5 * time.Minute)
	sqlDB.SetConnMaxIdleTime(2 * time.Minute)

	if err := sqlDB.Ping(); err != nil {
		log.Fatalf("[DB] PostgreSQL ping failed: %v", err)
	}

	log.Printf("[DB] ✅ PostgreSQL connected — %s:%s/%s", cfg.DBHost, cfg.DBPort, cfg.DBName)

	DB = db
	return db
}
