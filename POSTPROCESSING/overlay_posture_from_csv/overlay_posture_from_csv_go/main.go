package main

import (
	"bufio"
	"encoding/csv"
	"fmt"
	"image/color"
	"os"
	"path/filepath"
	"strconv"

	"github.com/cheggaaa/pb/v3"
	"gocv.io/x/gocv"
)

// Color palette
var palette = map[string]color.RGBA{
	"ir":  {R: 249, G: 82, B: 91, A: 255},
	"ird": {R: 134, G: 46, B: 56, A: 255},
	"bd":  {R: 25, G: 211, B: 197, A: 255},
	"bl":  {R: 138, G: 210, B: 211, A: 255},
	"yd":  {R: 252, G: 176, B: 33, A: 255},
	"yl":  {R: 254, G: 197, B: 87, A: 255},
	"vy":  {R: 240, G: 223, B: 0, A: 255},
	"db":  {R: 49, G: 51, B: 53, A: 255},
	"cg1": {R: 219, G: 219, B: 221, A: 255},
}

func main() {
	// Load the CSV file
	csvFilename := prompt("Enter the path to the CSV file: ")
	csvFile, err := os.Open(csvFilename)
	if err != nil {
		fmt.Println("Error opening CSV file:", err)
		return
	}
	defer csvFile.Close()

	reader := csv.NewReader(csvFile)
	rawData, err := reader.ReadAll()
	if err != nil {
		fmt.Println("Error reading CSV file:", err)
		return
	}

	// Extract body parts
	bodyParts := rawData[1]
	bodyPartNames := []string{}
	for i := 1; i < len(bodyParts); i += 3 {
		bodyPartNames = append(bodyPartNames, bodyParts[i])
	}

	// Prompt user to select a body part
	fmt.Println("Select a body part from the list:")
	for i, part := range bodyPartNames {
		fmt.Printf("%d: %s\n", i+1, part)
	}
	selectedIndex := promptInt("Enter the number corresponding to the body part: ")
	if selectedIndex < 1 || selectedIndex > len(bodyPartNames) {
		fmt.Println("Invalid selection")
		return
	}
	selectedBodyPart := bodyParts[(selectedIndex-1)*3+1]

	// Initialize arrays for coordinates and likelihood
	numLines := len(rawData) - 3
	xCoords := make([]float64, numLines)
	yCoords := make([]float64, numLines)
	likelihood := make([]float64, numLines)

	for i := 0; i < numLines; i++ {
		xCoords[i], _ = strconv.ParseFloat(rawData[i+3][(selectedIndex-1)*3+1], 64)
		yCoords[i], _ = strconv.ParseFloat(rawData[i+3][(selectedIndex-1)*3+2], 64)
		likelihood[i], _ = strconv.ParseFloat(rawData[i+3][(selectedIndex-1)*3+3], 64)
	}

	// Normalize likelihood
	minLikelihood, maxLikelihood := minMax(likelihood)
	normalizedLikelihood := normalize(likelihood, minLikelihood, maxLikelihood)

	// Generate colors from red to grey
	colors := generateColors(normalizedLikelihood)

	// Load the video file
	videoFilename := prompt("Enter the path to the video file: ")
	video, err := gocv.VideoCaptureFile(videoFilename)
	if err != nil {
		fmt.Println("Error opening video file:", err)
		return
	}
	defer video.Close()

	// Prompt the user to select the destination folder
	destinationPath := prompt("Enter the destination folder: ")
	if _, err := os.Stat(destinationPath); os.IsNotExist(err) {
		fmt.Println("Destination folder does not exist")
		return
	}

	// Generate the output video filename
	outputVideoFilename := filepath.Join(destinationPath, fmt.Sprintf("%s_overlayed_%s.avi", filepath.Base(videoFilename), selectedBodyPart))
	writer, err := gocv.VideoWriterFile(outputVideoFilename, "MJPG", 20, int(video.Get(gocv.VideoCaptureFrameWidth)), int(video.Get(gocv.VideoCaptureFrameHeight)), true)
	if err != nil {
		fmt.Println("Error creating video writer:", err)
		return
	}
	defer writer.Close()

	// Progress bar
	bar := pb.StartNew(numLines)

	// Process each frame
	for i := 0; i < numLines; i++ {
		bar.Increment()
		if ok := video.Grab(); !ok {
			break
		}
		img := gocv.NewMat()
		video.Read(&img)
		if img.Empty() {
			continue
		}

		// Draw the body part
		pt := gocv.NewPoint(int(xCoords[i]), int(yCoords[i]))
		gocv.Circle(&img, pt, 6, colors[i], 2)

		// Write the frame to the output video
		writer.Write(img)
		img.Close()
	}

	bar.Finish()
	fmt.Println("Overlay video saved to:", outputVideoFilename)
}

// Helper functions

func prompt(message string) string {
	fmt.Print(message)
	scanner := bufio.NewScanner(os.Stdin)
	scanner.Scan()
	return scanner.Text()
}

func promptInt(message string) int {
	fmt.Print(message)
	var value int
	fmt.Scanf("%d", &value)
	return value
}

func minMax(arr []float64) (float64, float64) {
	min, max := arr[0], arr[0]
	for _, val := range arr {
		if val < min {
			min = val
		}
		if val > max {
			max = val
		}
	}
	return min, max
}

func normalize(arr []float64, min, max float64) []float64 {
	norm := make([]float64, len(arr))
	for i, val := range arr {
		norm[i] = (val - min) / (max - min)
	}
	return norm
}

func generateColors(likelihood []float64) []color.RGBA {
	startColor := palette["ir"]
	endColor := palette["cg1"]
	colors := make([]color.RGBA, len(likelihood))

	for i, val := range likelihood {
		colors[i] = color.RGBA{
			R: uint8((1-val)*float64(startColor.R) + val*float64(endColor.R)),
			G: uint8((1-val)*float64(startColor.G) + val*float64(endColor.G)),
			B: uint8((1-val)*float64(startColor.B) + val*float64(endColor.B)),
			A: 255,
		}
	}
	return colors
}
