using Godot;
using System;

public partial class DebugScreen : Node2D
{

    private RichTextLabel textLabel;
    private RichTextLabel historyLabel;
    private Node _scale;
    private Node _mallot;

    public override void _Ready()
    {
        textLabel = GetNode<RichTextLabel>("Readings");
        historyLabel = GetNode<RichTextLabel>("History");

        var arduinoConn = ArduinoConn.Instance;

        if (arduinoConn != null)
        {
            arduinoConn.ReadingsUpdated += OnReadingsUpdated;
            arduinoConn.ConnectionStatusChanged += OnConnectionStatusChanged;
            arduinoConn.KnockDetected += OnKnockDetected;
        }

        _scale = GetNode("Scale");
        _mallot = GetNode("Mallot");
    }

    private void OnReadingsUpdated(int scale, int knock)
    {
        textLabel.Text = $"Scale: {scale}\nKnock: {knock}";

        // Convert scale from 0-1023 range to 30 to -30 range
        // Formula: newValue = maxNew - (value * (maxNew - minNew) / maxOld)
        float scaleMapped = 30 - (scale * 60f / 1023f);
        scaleMapped *= -1;
        GD.Print($"Mapped Scale: {scaleMapped}");
        _scale.Call("rotate_arms", scaleMapped);
    }

    private void OnConnectionStatusChanged(bool connected)
    {
        if (connected)
        {
            textLabel.Text += "\nConnected to Arduino";
        }
        else
        {
            textLabel.Text += "\nDisconnected from Arduino";
        }
    }

    private void OnKnockDetected(int knock)
    {
        historyLabel.Text += $"\nKnock detected: {knock}";
        GD.Print($"Knock detected: {knock}");
        _mallot.Call("strike");
    }

}
