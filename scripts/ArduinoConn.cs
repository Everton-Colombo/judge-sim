using Godot;
using System;
using System.IO.Ports;
using System.Threading;
using System.Collections.Generic;

public partial class ArduinoConn : Node
{
	// Add static singleton access
	public static ArduinoConn Instance { get; private set; }
	
	// Add signals for data updates
	[Signal]
	public delegate void ReadingsUpdatedEventHandler(int scale, int knock);
	
	[Signal]
	public delegate void ConnectionStatusChangedEventHandler(bool connected);
	
	[Signal]
	public delegate void KnockDetectedEventHandler(int knockValue);

	private SerialPort serialPort;
	private Thread pollingThread;
	private bool running = false;
	private readonly object lockObj = new object();
	
	// Data from Arduino
	private int scale = 512;
	private int knock = 0;
	private bool connectionError = false;
	private bool previousConnectionState = false;
	
	// For emitting signals at regular intervals
	private double elapsedTime = 0;
	private double updateInterval = 50; // Update every 50ms

	public override void _Ready()
	{
		// Set singleton instance
		Instance = this;
		
		Connect();
	}
	
	public override void _ExitTree()
	{
		Close();
	}
	
	private void Connect()
	{
		try
		{
			// Close any existing connection first
			if (serialPort != null && serialPort.IsOpen)
			{
				Close();
			}
			
			serialPort = new SerialPort();
			serialPort.PortName = "/dev/ttyACM0"; // Change to your Arduino port
			serialPort.BaudRate = 9600;
			serialPort.ReadTimeout = 500; // 500ms timeout
			serialPort.WriteTimeout = 500;
			serialPort.Open();
			
			GD.Print("Arduino connection established");
			
			// Wait for Arduino to reset (same as Python's sleep(2))
			Thread.Sleep(2000);
			
			running = true;
			connectionError = false;
			
			// Start polling thread
			pollingThread = new Thread(PollArduino);
			pollingThread.IsBackground = true; // Equivalent to daemon=True
			pollingThread.Start();
		}
		catch (Exception e)
		{
			GD.Print($"Could not connect to Arduino: {e.Message}");
			scale = 512;
			knock = 0;
			connectionError = true;
		}
	}
	
	private void PollArduino()
	{
		while (running)
		{
			try
			{
				lock (lockObj)
				{
					if (serialPort != null && serialPort.IsOpen)
					{
						// Clear input buffer
						serialPort.DiscardInBuffer();

						// Send request
						serialPort.Write("R");

						DateTime startTime = DateTime.Now;
						List<string> lines = new List<string>();

						while (true)
						{
							if (serialPort.BytesToRead > 0)
							{
								try
								{
									string line = serialPort.ReadLine().Trim();
									if (line == "END")
										break;
									lines.Add(line);
								}
								catch (Exception e)
								{
									GD.Print($"Serial read error: {e.Message}");
									break;
								}
							}

							// Check timeout (500ms)
							if ((DateTime.Now - startTime).TotalMilliseconds > 500)
								break;

							// Small sleep to prevent CPU hogging
							Thread.Sleep(5);
						}

						// Parse the data
						foreach (string line in lines)
						{
							if (line.StartsWith("SCALE:"))
							{
								try
								{
									scale = int.Parse(line.Split(':')[1]);
								}
								catch { }
							}
							else if (line.StartsWith("KNOCK:"))
							{
								try
								{
									knock = int.Parse(line.Split(':')[1]);
								}
								catch { }
							}
						}

						// Emit signal for updated readings
						CallDeferred(nameof(EmitReadingsSignal));
					}
				}
			}
			catch (Exception e)
			{
				GD.Print($"Polling error: {e.Message}");
				connectionError = true;

				// Try to reconnect - use CallDeferred to call from main thread
				CallDeferred(nameof(Reconnect));
			}

			Thread.Sleep((int)updateInterval);
		}
	}
	
	public void Reconnect()
	{
		if (connectionError)
		{
			GD.Print("Attempting to reconnect to Arduino...");
			try
			{
				Connect();
			}
			catch (Exception e)
			{
				GD.Print($"Reconnection failed: {e.Message}");
			}
		}
	}
	
	public bool IsConnected()
	{
		return !connectionError;
	}
	
	public (int, int) GetReadings()
	{
		int s, k;
		lock (lockObj)
		{
			s = scale;
			k = knock;
		}
		return (s, k);
	}
	
	private void EmitReadingsSignal()
	{
		EmitSignal(SignalName.ReadingsUpdated, scale, knock);

		// Emit signal when knock is detected (non-zero)
		if (knock > 0)
		{
			EmitSignal(SignalName.KnockDetected, knock);
			
			lock (lockObj)
			{
				knock = 0;
			}
		}
	}
	
	public override void _Process(double delta)
	{
		// Update the timer
		elapsedTime += delta;
		
		// Check for connection status changes
		if (previousConnectionState != IsConnected())
		{
			previousConnectionState = IsConnected();
			EmitSignal(SignalName.ConnectionStatusChanged, previousConnectionState);
		}
		
		// Emit readings signal at regular intervals
		if (elapsedTime >= updateInterval)
		{
			elapsedTime = 0;
			
			// Instead of updating text, just emit signal with current values
			var (scaleValue, knockValue) = GetReadings();
			EmitSignal(SignalName.ReadingsUpdated, scaleValue, knockValue);
		}
	}
	
	private void Close()
	{
		running = false;
		
		if (pollingThread != null && pollingThread.IsAlive)
		{
			pollingThread.Join(1000); // Wait up to 1 second for thread to exit
		}
		
		lock (lockObj)
		{
			if (serialPort != null && serialPort.IsOpen)
			{
				try
				{
					serialPort.Close();
					GD.Print("Arduino connection closed");
				}
				catch (Exception e)
				{
					GD.Print($"Error closing serial connection: {e.Message}");
				}
			}
		}
		
		serialPort = null;
	}
}
