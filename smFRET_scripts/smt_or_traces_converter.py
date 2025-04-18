#!/usr/bin/env python3
"""
Simple SMT File Reader - Reads .smt files and outputs to a single .txt file
"""

import os
import sys
import struct
import numpy as np
import pandas as pd

def read_smt_file(input_file, output_file=None):
    """Read a .smt file and convert to a readable txt file"""
    
    if output_file is None:
        output_file = os.path.splitext(input_file)[0] + '.txt'
    
    print(f"Reading: {input_file}")
    print(f"Output: {output_file}")
    
    try:
        with open(input_file, 'rb') as fid:
            # Read Header - add error checking for each read
            try:
                header_data = fid.read(4)
                if len(header_data) < 4:
                    raise EOFError("File is too small or corrupted: couldn't read peak count")
                cntPeak = struct.unpack('I', header_data)[0]  # uint32
                
                header_data = fid.read(4)
                if len(header_data) < 4:
                    raise EOFError("File is too small or corrupted: couldn't read frame count")
                cntFrame = struct.unpack('I', header_data)[0]  # uint32
                
                header_data = fid.read(4)
                if len(header_data) < 4:
                    raise EOFError("File is too small or corrupted: couldn't read offset")
                offset = struct.unpack('I', header_data)[0]    # uint32
                
                header_data = fid.read(1)
                if len(header_data) < 1:
                    raise EOFError("File is too small or corrupted: couldn't read channel count")
                cntChan = struct.unpack('B', header_data)[0]   # uint8
                
                header_data = fid.read(2)
                if len(header_data) < 2:
                    raise EOFError("File is too small or corrupted: couldn't read X size")
                xSize = struct.unpack('H', header_data)[0]     # uint16
                
                header_data = fid.read(2)
                if len(header_data) < 2:
                    raise EOFError("File is too small or corrupted: couldn't read Y size")
                ySize = struct.unpack('H', header_data)[0]     # uint16
                
                header_data = fid.read(4)
                if len(header_data) < 4:
                    raise EOFError("File is too small or corrupted: couldn't read background level")
                bgLevel = struct.unpack('I', header_data)[0]   # uint32
                
                header_data = fid.read(4)
                if len(header_data) < 4:
                    raise EOFError("File is too small or corrupted: couldn't read scaler")
                scaler = struct.unpack('I', header_data)[0]    # uint32
                
                header_data = fid.read(4)
                if len(header_data) < 4:
                    raise EOFError("File is too small or corrupted: couldn't read frame rate")
                frameRate = struct.unpack('f', header_data)[0] # float
                
                header_data = fid.read(4)
                if len(header_data) < 4:
                    raise EOFError("File is too small or corrupted: couldn't read peak radius")
                peakRadius = struct.unpack('f', header_data)[0] # float
                
                header_data = fid.read(4)
                if len(header_data) < 4:
                    raise EOFError("File is too small or corrupted: couldn't read peak sigma")
                peakSigma = struct.unpack('f', header_data)[0] # float
            
            except EOFError as e:
                print(f"Error reading header: {e}")
                print(f"File may be corrupted or in an incorrect format.")
                sys.exit(1)
            
            header_info = {
                "Number of Peaks": cntPeak,
                "Number of Frames": cntFrame,
                "Data Offset": offset,
                "Number of Channels": cntChan,
                "X Size": xSize,
                "Y Size": ySize,
                "Background Level": bgLevel,
                "Scaler": scaler,
                "Frame Rate": frameRate,
                "Peak Radius": peakRadius,
                "Peak Sigma": peakSigma
            }
            
            # Print header info for debugging
            print("\nFile Header Information:")
            for key, value in header_info.items():
                print(f"{key}: {value}")
            
            # Validate the header makes sense
            if cntPeak <= 0 or cntPeak > 10000:
                print(f"Warning: Unusual number of peaks: {cntPeak}")
            if cntFrame <= 0 or cntFrame > 100000:
                print(f"Warning: Unusual number of frames: {cntFrame}")
            if cntChan <= 0 or cntChan > 10:
                print(f"Warning: Unusual number of channels: {cntChan}")
            
            # Read Peaks with error checking
            peaks_data = []
            
            try:
                for i in range(cntPeak):
                    peak_info = {"Peak": i+1}
                    for j in range(cntChan):
                        data = fid.read(4)
                        if len(data) < 4:
                            raise EOFError(f"EOF reached while reading peak {i+1}, channel {j+1} X position")
                        peak_info[f"X Position (Ch{j+1})"] = struct.unpack('f', data)[0]
                        
                        data = fid.read(4)
                        if len(data) < 4:
                            raise EOFError(f"EOF reached while reading peak {i+1}, channel {j+1} X SD")
                        peak_info[f"X SD (Ch{j+1})"] = struct.unpack('f', data)[0]
                        
                        data = fid.read(4)
                        if len(data) < 4:
                            raise EOFError(f"EOF reached while reading peak {i+1}, channel {j+1} Y position")
                        peak_info[f"Y Position (Ch{j+1})"] = struct.unpack('f', data)[0]
                        
                        data = fid.read(4)
                        if len(data) < 4:
                            raise EOFError(f"EOF reached while reading peak {i+1}, channel {j+1} Y SD")
                        peak_info[f"Y SD (Ch{j+1})"] = struct.unpack('f', data)[0]
                        
                        data = fid.read(4)
                        if len(data) < 4:
                            raise EOFError(f"EOF reached while reading peak {i+1}, channel {j+1} Is Good")
                        peak_info[f"Is Good (Ch{j+1})"] = struct.unpack('I', data)[0]
                    peaks_data.append(peak_info)
            
            except EOFError as e:
                print(f"Error reading peak data: {e}")
                print("Will attempt to continue with data read so far...")
            
            # Attempt to jump to data section
            try:
                current_pos = fid.tell()
                if current_pos > offset:
                    print(f"Warning: Current position ({current_pos}) is already past the specified data offset ({offset})")
                    print("Will continue reading from current position")
                else:
                    fid.seek(offset)
                    print(f"Successfully jumped to data offset: {offset}")
            except Exception as e:
                print(f"Warning: Could not seek to data offset: {e}")
                print("Will continue reading from current position")
            
            # Read data section with better error handling
            all_data = []
            try:
                for i in range(min(cntPeak, len(peaks_data))):
                    peak_data = {"Peak": i+1}
                    # Read signal intensity
                    for j in range(cntChan):
                        signal_intensity = []
                        for k in range(cntFrame):
                            try:
                                data = fid.read(4)
                                if len(data) < 4:
                                    print(f"Warning: EOF reached while reading signal intensity for peak {i+1}, channel {j+1}, frame {k+1}")
                                    break
                                signal_intensity.append(struct.unpack('f', data)[0])
                            except Exception as e:
                                print(f"Error reading signal intensity for peak {i+1}, channel {j+1}, frame {k+1}: {e}")
                                break
                        peak_data[f"Signal Intensity (Ch{j+1})"] = signal_intensity
                    
                    # Read background intensity
                    for j in range(cntChan):
                        background_intensity = []
                        for k in range(cntFrame):
                            try:
                                data = fid.read(4)
                                if len(data) < 4:
                                    print(f"Warning: EOF reached while reading background intensity for peak {i+1}, channel {j+1}, frame {k+1}")
                                    break
                                background_intensity.append(struct.unpack('f', data)[0])
                            except Exception as e:
                                print(f"Error reading background intensity for peak {i+1}, channel {j+1}, frame {k+1}: {e}")
                                break
                        peak_data[f"Background Intensity (Ch{j+1})"] = background_intensity
                    
                    all_data.append(peak_data)
            except Exception as e:
                print(f"Error reading intensity data: {e}")
                print("Will attempt to continue with data read so far...")
        
        # Write available data to a readable text file
        with open(output_file, 'w') as out_file:
            # Write header information
            out_file.write("=== SMT FILE HEADER INFORMATION ===\n")
            for key, value in header_info.items():
                out_file.write(f"{key}: {value}\n")
            
            # Write peak information
            out_file.write("\n=== PEAK POSITIONS AND PROPERTIES ===\n")
            for peak in peaks_data:
                out_file.write(f"\nPeak {peak['Peak']}:\n")
                for key, value in peak.items():
                    if key != "Peak":
                        out_file.write(f"  {key}: {value}\n")
            
            # Write signal data if available
            if all_data:
                # Write signal data (first peak only to keep file manageable)
                out_file.write("\n=== SIGNAL DATA (First Peak Only) ===\n")
                peak_data = all_data[0]
                out_file.write(f"Peak 1 Data:\n")
                
                # Create a table with frame, signal and background for each channel
                out_file.write("Frame\t")
                for j in range(cntChan):
                    out_file.write(f"Signal(Ch{j+1})\tBackground(Ch{j+1})\t")
                out_file.write("\n")
                
                # Determine how many frames we can show
                signal_key = f"Signal Intensity (Ch1)"
                if signal_key in peak_data:
                    available_frames = len(peak_data[signal_key])
                    display_frames = min(20, available_frames)
                    
                    for k in range(display_frames):
                        out_file.write(f"{k+1}\t")
                        for j in range(cntChan):
                            signal_key = f"Signal Intensity (Ch{j+1})"
                            bg_key = f"Background Intensity (Ch{j+1})"
                            
                            if signal_key in peak_data and k < len(peak_data[signal_key]):
                                out_file.write(f"{peak_data[signal_key][k]:.4f}\t")
                            else:
                                out_file.write("N/A\t")
                                
                            if bg_key in peak_data and k < len(peak_data[bg_key]):
                                out_file.write(f"{peak_data[bg_key][k]:.4f}\t")
                            else:
                                out_file.write("N/A\t")
                                
                        out_file.write("\n")
                    
                    if cntFrame > display_frames:
                        out_file.write("...\n")
                        out_file.write(f"Note: Only showing first {display_frames} of {cntFrame} frames\n")
                else:
                    out_file.write("No signal data available for the first peak.\n")
                
                # Output summary for remaining peaks
                if cntPeak > 1:
                    out_file.write(f"\nNote: File contains data for {cntPeak} peaks. Only the first peak's data is shown above.\n")
            else:
                out_file.write("\nNo signal data was successfully read from the file.\n")
            
        print(f"Conversion complete! Data written to {output_file}")
            
    except EOFError as e:
        print(f"Error: {e}")
        print("The file appears to be truncated or in an incorrect format.")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        print(f"Error occurred at line: {sys.exc_info()[2].tb_lineno}")
        sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print("Usage: python simple_smt_reader.py input.smt [output.txt]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    # Verify input file exists
    if not os.path.exists(input_file):
        # If input doesn't end with .smt, try appending it
        if not input_file.lower().endswith('.smt'):
            potential_file = input_file + '.smt'
            if os.path.exists(potential_file):
                input_file = potential_file
            else:
                print(f"Error: Input file '{input_file}' does not exist")
                sys.exit(1)
        else:
            print(f"Error: Input file '{input_file}' does not exist")
            sys.exit(1)
    
    # Print file size for debugging
    file_size = os.path.getsize(input_file)
    print(f"File size: {file_size} bytes")
    
    # Process the file
    read_smt_file(input_file, output_file)

if __name__ == "__main__":
    main()
