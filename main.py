import requests
import time
import hashlib
from pathlib import Path
import logging
from datetime import datetime
import os
import xml.etree.ElementTree as ET
from io import BytesIO
import re


# Logging configuration (unchanged)
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')

def calculate_hash(content):
    return hashlib.sha256(content.encode('utf-8')).hexdigest()

def minify_xml(xml_string, keep_declaration=True):
    """Minify XML aggressively to reduce file size"""
    # Remove XML declaration if not needed
    if not keep_declaration:
        xml_string = re.sub(r'<\?xml[^>]*\?>', '', xml_string)
    
    # Remove DOCTYPE declarations to save space if not essential
    xml_string = re.sub(r'<!DOCTYPE[^>]*>', '', xml_string)
    
    # Remove comments
    xml_string = re.sub(r'<!--.*?-->', '', xml_string, flags=re.DOTALL)
    
    # Remove leading/trailing whitespace between tags
    xml_string = re.sub(r'>\s+<', '><', xml_string)
    
    # Remove unnecessary whitespace at the beginning of lines
    xml_string = re.sub(r'^\s+', '', xml_string, flags=re.MULTILINE)
    
    # Remove unnecessary whitespace at the end of lines
    xml_string = re.sub(r'\s+$', '', xml_string, flags=re.MULTILINE)
    
    # Remove extra line breaks
    xml_string = re.sub(r'\n+', '\n', xml_string)

    # Convert empty elements to shortest form (if not already done)
    # For example: <element></element> to <element/>
    xml_string = re.sub(r'<([^/>\s]+)([^>]*)></\1>', r'<\1\2/>', xml_string)
    
    # Normalize common XML entities to save space
    replacements = [
        ('&quot;', '"'), 
        ('&apos;', "'"),
        ('&amp;', '&'),
        ('&lt;', '<'),
        ('&gt;', '>')
    ]
    
    # Only replace entities that won't break XML structure
    for entity, char in replacements:
        # Don't replace entities inside attribute values that would break XML
        parts = re.split(r'(<[^>]*>)', xml_string)
        for i in range(len(parts)):
            # If this is not a tag, safe to replace all entities
            if i % 2 == 0:
                parts[i] = parts[i].replace(entity, char)
            # If it's a tag, only replace in safe contexts
            else:
                # Don't replace entities that would break attribute values
                if char not in ['"', "'", '<', '>']:
                    parts[i] = parts[i].replace(entity, char)
        xml_string = ''.join(parts)
    
    # Optimize attribute spacing (no spaces around =)
    xml_string = re.sub(r'\s*=\s*', '=', xml_string)
    
    # Remove extra spaces within tags
    xml_string = re.sub(r'<([^/>\s]+)\s+', r'<\1 ', xml_string)
    xml_string = re.sub(r'\s+/>', r'/>', xml_string)
    
    return xml_string.strip()

def download_and_compare(url, destination_directory, file_name="web_file"):
    previous_content = None
    previous_hash = None
    base_destination_path = Path(destination_directory)
    base_destination_path.mkdir(parents=True, exist_ok=True)

    # Create daily folder with format nextbikes-dd-mm-yyyy
    today = datetime.now()
    daily_folder_name = f"nextbikes-{today.strftime('%d-%m-%Y')}"
    destination_path = base_destination_path / daily_folder_name
    destination_path.mkdir(parents=True, exist_ok=True)

    # Find most recent file across all daily folders for comparison
    all_xml_files = []
    for folder in base_destination_path.glob("nextbikes-*"):
        if folder.is_dir():
            all_xml_files.extend(folder.glob(f'{file_name}_*.xml'))
    
    existing_files = sorted(all_xml_files, key=os.path.getmtime, reverse=True)
    
    if existing_files:
        try:
            with open(existing_files[0], 'r', encoding='utf-8') as f:
                previous_content = f.read()
                previous_hash = calculate_hash(previous_content)
        except Exception as e:
            logging.error(f"Error reading previous file '{existing_files[0]}': {e}")

    try:
        response = requests.get(url)
        response.raise_for_status()
        current_content = response.content  # Get content as bytes

        # Parse XML and minify it
        try:
            # First parse to validate it's correct XML
            root = ET.fromstring(current_content)
            
            # Optimization: convert to string without XML declaration to minimize size
            buffer = BytesIO()
            ET.ElementTree(root).write(buffer, encoding='utf-8', xml_declaration=False, short_empty_elements=True, method="xml")
            xml_string = buffer.getvalue().decode('utf-8')
            
            # Apply aggressive minification
            minified_content = minify_xml(xml_string, keep_declaration=False)
            current_hash = calculate_hash(minified_content)

            if previous_hash is None or current_hash != previous_hash:
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                filename = f"{file_name}_{timestamp}.xml"
                destination_file_path = destination_path / filename
                with open(destination_file_path, 'w', encoding='utf-8') as f:
                    f.write(minified_content)
                
                # Calculate and log file size
                file_size = os.path.getsize(destination_file_path)
                file_size_kb = file_size / 1024
                
                if previous_hash is None:
                    logging.info(f"Initial download saved as minified file '{destination_file_path}'. Size: {file_size_kb:.2f} KB. Hash: {current_hash[:8]}...")
                else:
                    logging.info(f"Change detected! New content saved as minified file '{destination_file_path}'. Size: {file_size_kb:.2f} KB. Previous hash: {previous_hash[:8]}..., Current hash: {current_hash[:8]}...")
                return True
            else:
                logging.info("No changes detected.")
                return False

        except ET.ParseError as e:
            logging.error(f"Error parsing XML: {e}. Saving original content with minification.")
            text_content = response.text
            # Try to minify even if it's not valid XML
            minified_content = minify_xml(text_content)
            current_hash = calculate_hash(minified_content)
            if previous_hash is None or current_hash != previous_hash:
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                filename = f"{file_name}_{timestamp}.xml"
                destination_file_path = destination_path / filename
                with open(destination_file_path, 'w', encoding='utf-8') as f:
                    f.write(minified_content)
                
                # Calculate and log file size
                file_size = os.path.getsize(destination_file_path)
                file_size_kb = file_size / 1024
                
                logging.info(f"Initial download saved as minified file '{destination_file_path}'. Size: {file_size_kb:.2f} KB. Hash: {current_hash[:8]}...")
            else:
                logging.info("No changes detected.")
            return False

    except requests.exceptions.RequestException as e:
        logging.error(f"Error downloading '{url}': {e}")
        return False
    except Exception as e:
        logging.error(f"Unexpected error occurred: {e}")
        return False

if __name__ == "__main__":
    target_url = os.environ.get("TARGET_URL", "https://iframe.nextbike.net/maps/nextbike-live.xml?&city=532&domains=bo")
    relative_destination_directory = "data"
    interval_seconds = int(os.environ.get("INTERVAL_SECONDS", "15"))
    file_name = os.environ.get("FILE_NAME", "nextbikes_bilbao")

    if target_url == "YOUR_URL_HERE":
        print("Please replace 'YOUR_URL_HERE' with the URL you want to monitor.")
    else:
        logging.info(f"Starting monitoring of '{target_url}' every {interval_seconds} seconds.")
        logging.info(f"Files will be saved in daily folders (nextbikes-dd-mm-yyyy) within '{relative_destination_directory}' directory.")
        try:
            while True:
                download_and_compare(target_url, relative_destination_directory, file_name)
                time.sleep(interval_seconds)
        except KeyboardInterrupt:
            logging.info("Monitoring stopped by user.")