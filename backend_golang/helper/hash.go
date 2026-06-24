package helper

import "golang.org/x/crypto/bcrypt"

// HashPassword hashes a plain-text password using bcrypt with cost 12.
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 12)
	return string(bytes), err
}

// CheckPassword compares a bcrypt hash against a plain-text password.
// Returns true if they match.
func CheckPassword(hash, password string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil
}
