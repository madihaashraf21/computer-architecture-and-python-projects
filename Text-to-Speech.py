import pyttsx3

file_path = r"C:\Users\Mrd74\OneDrive\Desktop\option1\output.txt"

try:
    with open(file_path, "r") as file:
        text = file.read()

    print("Detected Text:", text)

    engine = pyttsx3.init()

    engine.setProperty('rate', 150)
    engine.setProperty('volume', 1.0)

    engine.say(text)

    print("\nSpeaking...\n")

    engine.runAndWait()

except FileNotFoundError:
    print("ERROR: output.txt file not found!")

except Exception as e:
    print("ERROR:", e)