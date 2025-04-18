#!/usr/bin/env python3
import os
import sys
import numpy as np
from PIL import Image
import struct
import argparse
import matplotlib.pyplot as plt

def convert_pma_to_tiff(pma_file, debug=False, byte_swap=False, normalize=False, flip=False, manual_frames=None):
    """
    Convert a single PMA file to TIFF stack with better frame handling.
    
    Args:
        pma_file (str): Path to the PMA file
        debug (bool): Enable debug mode with extra output
        byte_swap (bool): Swap byte order (endianness)
        normalize (bool): Normalize pixel values to use full range
        flip (bool): Flip image to try different orientations
        manual_frames (int): Manually specified number of frames
    """
    if not os.path.exists(pma_file):
        print(f"Error: File '{pma_file}' not found.")
        return
    
    if not pma_file.lower().endswith('.pma'):
        print(f"Error: File '{pma_file}' is not a .pma file.")
        return
    
    print(f"Processing: {pma_file}")
    
    try:
        with open(pma_file, 'rb') as fid:
            # Read the first 100 bytes for debugging
            if debug:
                fid.seek(0)
                header_bytes = fid.read(100)
                print(f"First 100 bytes (hex): {header_bytes.hex()}")
                fid.seek(0)
            
            # Read image dimensions (first 4 bytes - 2 uint16 values)
            sizex_bytes = fid.read(2)
            sizey_bytes = fid.read(2)
            
            # Try both endianness options if requested
            if byte_swap:
                sizex = struct.unpack('>H', sizex_bytes)[0]  # Big endian
                sizey = struct.unpack('>H', sizey_bytes)[0]
            else:
                sizex = struct.unpack('<H', sizex_bytes)[0]  # Little endian (default)
                sizey = struct.unpack('<H', sizey_bytes)[0]
            
            print(f"Image dimensions: {sizex} x {sizey}")
            
            # Sanity check dimensions
            if sizex < 10 or sizey < 10 or sizex > 10000 or sizey > 10000:
                print(f"WARNING: Suspicious dimensions: {sizex} x {sizey}")
                print("Trying alternative byte order...")
                
                # Try the opposite endianness
                if byte_swap:
                    sizex = struct.unpack('<H', sizex_bytes)[0]
                    sizey = struct.unpack('<H', sizey_bytes)[0]
                else:
                    sizex = struct.unpack('>H', sizex_bytes)[0]
                    sizey = struct.unpack('>H', sizey_bytes)[0]
                
                print(f"Alternative dimensions: {sizex} x {sizey}")
            
            # Check the number of frames
            fid.seek(0, 2)  # Seek to end of file
            file_size = fid.tell()
            dtype = 2  # Size of uint16 in bytes
            
            # Calculate frames - accounting for 2 byte header per frame
            frame_size = sizex * sizey * dtype + 2
            calculated_frames = int((file_size - 4) / frame_size)
            
            # Use manual frame count if provided
            if manual_frames is not None and manual_frames > 0:
                nframe = manual_frames
                print(f"Using manually specified frame count: {nframe}")
            else:
                nframe = calculated_frames
                print(f"Calculated number of frames: {nframe}")
            
            print(f"File size: {file_size} bytes")
            print(f"Expected frame data size: {frame_size} bytes per frame")
            print(f"Total data size for all frames: {nframe * frame_size + 4} bytes")
            
            if nframe < 1:
                print("Error: Could not determine valid frame count.")
                return
            
            # Go back to position after dimensions
            fid.seek(4, 0)
            
            # Create output TIFF file
            output_filename = os.path.splitext(pma_file)[0] + '.tif'
            print(f"Output file will be: {output_filename}")
            
            # Also save debug images
            os.makedirs("debug_frames", exist_ok=True)
            
            # Storage for all frames to create a stack
            all_frames = []
            
            for j in range(nframe):
                try:
                    # Read 2-byte frame header
                    frame_header = fid.read(2)
                    if len(frame_header) < 2:
                        print(f"\nWarning: Reached end of file at frame {j+1}. File may contain fewer frames than calculated.")
                        break
                        
                    if debug and j < 5:  # Show headers for first few frames
                        print(f"Frame {j+1} header (hex): {frame_header.hex()}")
                    
                    # Read image data for this frame
                    img_bytes = fid.read(sizex * sizey * 2)
                    
                    if len(img_bytes) < sizex * sizey * 2:
                        print(f"\nWarning: Incomplete data for frame {j+1}. Stopping.")
                        break
                    
                    # Convert bytes to numpy array of uint16
                    if byte_swap:
                        dt = np.dtype(np.uint16)
                        dt = dt.newbyteorder('>')
                        image = np.frombuffer(img_bytes, dtype=dt)
                    else:
                        image = np.frombuffer(img_bytes, dtype=np.uint16)
                    
                    # Reshape
                    image = image.reshape((sizex, sizey))
                    
                    # Transpose the image
                    image = image.transpose()
                    
                    # Flip if requested
                    if flip:
                        image = np.flip(image, axis=0)
                    
                    # Normalize if requested (per frame)
                    if normalize:
                        if image.max() > image.min():
                            image = ((image - image.min()) * (65535.0 / (image.max() - image.min()))).astype(np.uint16)
                    
                    # Save debug images for a few frames
                    if debug and j < 5:  # Save first 5 frames as debug images
                        plt.figure(figsize=(10, 8))
                        plt.imshow(image, cmap='gray')
                        plt.colorbar(label='Pixel Value')
                        plt.title(f'Frame {j+1} (min={image.min()}, max={image.max()}, mean={image.mean():.2f})')
                        plt.savefig(f"debug_frames/frame_{j+1}.png")
                        plt.close()
                    
                    # Add to list of frames
                    all_frames.append(Image.fromarray(image))
                    
                    sys.stdout.write(f"\rProcessed frame {j+1}/{nframe}")
                    sys.stdout.flush()
                
                except Exception as e:
                    print(f"\nError processing frame {j+1}: {str(e)}")
                    break
            
            print(f"\nSuccessfully processed {len(all_frames)} frames")
            
            # Save all frames as a multi-page TIFF
            if all_frames:
                try:
                    # Save first frame
                    all_frames[0].save(
                        output_filename,
                        save_all=True,
                        append_images=all_frames[1:] if len(all_frames) > 1 else [],
                        compression=None  # No compression for troubleshooting
                    )
                    print(f"TIFF stack with {len(all_frames)} frames saved as: {output_filename}")
                    print(f"File size of output TIFF: {os.path.getsize(output_filename)} bytes")
                except Exception as e:
                    print(f"Error saving TIFF stack: {str(e)}")
                    
                    # Try alternative saving method
                    print("Trying alternative TIFF saving method...")
                    try:
                        first_frame = all_frames[0]
                        first_frame.save(output_filename)
                        
                        if len(all_frames) > 1:
                            for i, frame in enumerate(all_frames[1:], 1):
                                frame.save(output_filename, append=True)
                                if i % 10 == 0:
                                    sys.stdout.write(f"\rSaving frame {i}/{len(all_frames)}")
                                    sys.stdout.flush()
                        
                        print(f"\nTIFF stack saved with alternative method as: {output_filename}")
                        print(f"File size of output TIFF: {os.path.getsize(output_filename)} bytes")
                    except Exception as e2:
                        print(f"Error with alternative saving method: {str(e2)}")
            else:
                print("No frames were successfully processed. Cannot create TIFF stack.")
    
    except Exception as e:
        print(f"Error processing file: {str(e)}")
        import traceback
        traceback.print_exc()

def main():
    # Set up command line argument parsing
    parser = argparse.ArgumentParser(description='Convert PMA files to TIFF stacks')
    parser.add_argument('pma_file', help='Path to the PMA file to convert')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')
    parser.add_argument('--byte-swap', action='store_true', help='Try swapping byte order')
    parser.add_argument('--normalize', action='store_true', help='Normalize pixel values')
    parser.add_argument('--flip', action='store_true', help='Flip image orientation')
    parser.add_argument('--frames', type=int, help='Manually specify number of frames')
    
    # Parse arguments
    args = parser.parse_args()
    
    # Convert the specified file
    convert_pma_to_tiff(args.pma_file, args.debug, args.byte_swap, args.normalize, args.flip, args.frames)

if __name__ == "__main__":
    main()
