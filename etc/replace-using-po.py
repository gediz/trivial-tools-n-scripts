#!/usr/bin/python

import argparse
from os import path
import polib

# Parse arguments
app_desc = 'Replace translatable strings in Akira source using specified PO file'
arg_parser = argparse.ArgumentParser(description=app_desc)

arg_parser.add_argument('PO', metavar='po', type=str,
    help='PO file path')

arg_parser.add_argument('Directory', metavar='dir', type=str,
    help='Akira directory path')

args = arg_parser.parse_args()

po_path = args.PO
akira_path = args.Directory

# Do some basic check
if not path.isfile(po_path):
    print("Invalid file: " + po_path)
    quit()

if not path.isdir(akira_path):
    print("Invalid directory: " + akira_path)
    quit()

akira_src = path.join(akira_path, "src")
if not path.isdir(akira_src):
    print("No 'src' directory found in the following path: " + akira_path)
    quit()

# Parse PO file
po = polib.pofile(po_path)

valid_entries = [e for e in po.translated_entries() if not e.obsolete]
for entry in valid_entries:
    for occ in entry.occurrences:
        occ_path, occ_line = occ
        occ_path = path.join(akira_src, occ_path)
        occ_line = int(occ_line)
        
        with open(occ_path, 'r') as f:
            # read a list of lines into data
            f_data = f.readlines()
        
        original_data = f_data[occ_line - 1]

        # escape newline character, otherwise a literal newline would be looked for.
        entry.msgid = entry.msgid.replace("\n", "\\n")
        entry.msgstr = entry.msgstr.replace("\n", "\\n")

        old_translation = "\"{}\"".format(entry.msgid.encode('utf-8'))
        new_translation = "\"{}\"".format(entry.msgstr.encode('utf-8'))
        new_data = original_data.replace(old_translation, new_translation)
        
        # change the line
        f_data[occ_line - 1] = new_data

        # and write everything back
        with open(occ_path, 'w') as f:
            f.writelines(f_data)

print("Done")