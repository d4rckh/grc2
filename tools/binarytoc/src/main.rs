use std::env;
use std::fs;
use std::fs::OpenOptions;
use std::io::prelude::*;

fn main() {
    let args: Vec<String> = env::args().collect();
    let mut iter = args.iter();
    let bin_path = iter.nth(1).expect("Provide path to binary");
    let out_path = iter.next().expect("Provide path to output");

    let bin: Vec<u8> = fs::read(bin_path).expect("Failed to read file contents");
    
    let mut file = OpenOptions::new()
        .write(true)
        .append(true)
        .open(out_path)
        .unwrap();

    for ch in bin {
        write!(file, "\\x{ch:x}").unwrap();
    }
}
