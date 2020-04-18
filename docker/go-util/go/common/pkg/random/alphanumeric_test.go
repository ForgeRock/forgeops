package random

import (
	"testing"

	"github.com/stretchr/testify/suite"
)

type AlphanumericTestSuite struct {
	suite.Suite
}

type MockRandomInteger struct {
	calls int
}

func (m *MockRandomInteger) Random(n int) int {
	seededSequence := []int{5, 8, 2, 9, 1, 14, 5, 9}
	if m.calls == len(seededSequence) {
		m.calls = 0
	}

	defer func() {
		m.calls++
	}()
	return seededSequence[m.calls]
}

func (a AlphanumericTestSuite) TestRandomAlphanumericString() {
	expected := "fic"
	m := new(MockRandomInteger)
	actual := AlphanumericStringOfLength(3, m.Random)

	a.Equal(expected, actual)
}

func TestSuite(t *testing.T) {
	suite.Run(t, new(AlphanumericTestSuite))
}
