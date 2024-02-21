package interactions

import (
	"fmt"

	"github.com/manifoldco/promptui"
)

// UserInput will prompt the user to input a value with the passed in label.
// If no input is provided by the user defaultValue is used.
// If an error occurs while getting user input, the returned error will be non-nil.
// The value of result will always be what the user input or the defaultValue.
func UserInput(label, defaultValue string) (response string, err error) {
	lbl := label

	if defaultValue != "" {
		lbl = fmt.Sprintf("Input %s (Press enter to use default -> %s):", lbl, defaultValue)
	}

	prompt := promptui.Prompt{
		Label: lbl,
	}

	response, err = prompt.Run()
	if err != nil {
		return
	}

	// If the user does not pass a response, the default value is used.
	if response == "" {
		response = defaultValue
	}

	return response, err

}
