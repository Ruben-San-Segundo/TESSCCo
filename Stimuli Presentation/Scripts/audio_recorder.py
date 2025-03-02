import pyaudio
import wave



def record_audio(filename, stop_event):

    chunk = 1024  # Record in chunks of 1024 samples
    sample_format = pyaudio.paInt16  # 16 bits per sample
    channels = 1
    fs = 44100  # Record at 44100 samples per second

    p = pyaudio.PyAudio()  # Create an interface to PortAudio

    stream = p.open(format=sample_format,channels=channels,rate=fs,frames_per_buffer=chunk,input=True)
    print('Recording audio')

    frames = []  # Initialize array to store frames

    # Store data in chunks if chunks have  data
    while not stop_event.is_set():
        try:
            data = stream.read(chunk)
            frames.append(data)
        except KeyboardInterrupt:
            break


    # Stop and close the stream 
    stream.stop_stream()
    stream.close()
    # Terminate the PortAudio interface
    p.terminate()

    print('Finished recording')

    # Save the recorded data as a WAV file
    wf = wave.open(filename, 'wb')
    wf.setnchannels(channels)
    wf.setsampwidth(p.get_sample_size(sample_format))
    wf.setframerate(fs)
    wf.writeframes(b''.join(frames))
    wf.close()
