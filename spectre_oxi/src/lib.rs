use nvim_oxi::{self as oxi, Dictionary, Function, Object};
use regex::Regex;
use std::{
    fs::File,
    io::{BufRead, BufReader, Write},
    sync::Mutex,
};

#[macro_use]
extern crate lazy_static;

// https://docs.rs/regex/latest/regex/index.html
// I follow the example of the docs to reuse regex when running it multiple times
lazy_static! {
    static ref CACHE_PATTERN: Mutex<String> = Mutex::new("".to_string());
    static ref CACHE_REGEX: Mutex<Regex> = Mutex::new(Regex::new(r"").unwrap());
}

#[oxi::module]
fn spectre_oxi() -> oxi::Result<Dictionary> {
    Ok(Dictionary::from_iter([
        (
            "replace_file",
            Object::from(Function::from_fn(
                |(file_path, lnum, search_query, replace_query): (String, i32, String, String)| {
                    Ok(replace_file(file_path, lnum, search_query, replace_query))
                },
            )),
        ),
        (
            "replace_all",
            Object::from(Function::from_fn(
                |(search_query, replace_query, text): (String, String, String)| {
                    Ok(replace_all(search_query, replace_query, text))
                },
            )),
        ),
        (
            "matchstr",
            Object::from(Function::from_fn(
                |(search_text, search_query): (String, String)| {
                    Ok(matchstr(search_text, search_query))
                },
            )),
        ),
    ]))
}

fn get_static_regex(pattern: String) -> Result<&'static Mutex<Regex>, String> {
    if pattern != *CACHE_PATTERN.lock().unwrap() {
        *CACHE_PATTERN.lock().unwrap() = pattern.clone();
        let regex = Regex::new(&pattern);
        return if let Ok(r) = regex {
            *CACHE_REGEX.lock().unwrap() = r;
            Ok(&CACHE_REGEX)
        } else {
            Err("Invalid regex".to_string())
        };
    }
    Ok(&CACHE_REGEX)
}

/// Similar to vim.fn.matchstr()
/// get the match of the search_query
/// it return empty string when the text is not match
fn matchstr(search_text: String, search_query: String) -> String {
    if let Ok(r) = get_static_regex(search_query) {
        let regex = r.lock().unwrap();
        if regex.is_match(&search_text) {
            return regex
                .captures(&search_text)
                .unwrap()
                .get(0)
                .unwrap()
                .as_str()
                .to_string();
        }
    }
    String::new()
}

/// Replaces all non-overlapping matches in `text` with the replacement provided.
fn replace_all(search_query: String, replace_query: String, text: String) -> String {
    if let Ok(r) = get_static_regex(search_query) {
        let regex = r.lock().unwrap();
        return regex.replace_all(&text, &replace_query).to_string();
    }
    text
}

/// Replace text on specify line number of file
fn replace_file(file_path: String, lnum: i32, search_query: String, replace_query: String) -> bool {
    if !File::open(&file_path).is_ok() {
        return false;
    }
    let static_regex = get_static_regex(search_query);
    if static_regex.is_err() {
        return false;
    }
    let regex = static_regex.unwrap().lock().unwrap();
    let file = File::open(&file_path);
    if file.is_err() {
        return false;
    }
    let f = BufReader::new(file.unwrap());
    let mut lines: Vec<String> = Vec::new();
    let mut is_modified = false;

    // Is this good?
    // I only want replace 1 line with another line
    let mut line_number = 1;
    for line in f.lines() {
        // it only read a valid utf-8
        if line.is_err() {
            return false;
        }
        let text = line.unwrap();
        if line_number == (lnum as usize) {
            let new_line = regex.replace_all(&text, &replace_query).to_string();
            if new_line != text {
                is_modified = true;
                lines.push(new_line);
            } else {
                lines.push(text);
            }
        } else {
            lines.push(text);
        }
        line_number += 1;
    }
    if is_modified {
        let mut new_file = File::create(&file_path).unwrap();
        new_file.write_all(lines.join("\n").as_bytes()).unwrap();
        return true;
    }
    false
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Read;

    #[test]
    fn test_matchstr_date() {
        assert_eq!(
            matchstr(
                "date: 2012-03-04".to_string(),
                r"(\d{4})-(\d{2})-(\d{2})".to_string()
            ),
            "2012-03-04"
        );
    }

    #[test]
    fn test_replace_simple() {
        assert_eq!(
            replace_all("bc".to_string(), "OOOa".to_string(), "abcdef".to_string(),),
            "aOOOadef"
        );
    }

    #[test]
    fn test_replace_numbered_group() {
        assert_eq!(
            replace_all(
                "(bcd)".to_string(),
                "${1}a".to_string(),
                "bcdef".to_string(),
            ),
            "bcdaef"
        );
    }

    #[test]
    fn test_replace_number() {
        assert_eq!(
            replace_all(
                r"\d+".to_string(),
                "X".to_string(),
                "abcdef 123 aaa".to_string(),
            ),
            "abcdef X aaa"
        );
    }

    #[test]
    fn test_replace_flag_ignorecase() {
        assert_eq!(
            replace_all(
                r"(?i)unique".to_string(),
                "data".to_string(),
                "Unique".to_string(),
            ),
            "data"
        );
    }

    #[test]
    fn test_replace_file() {
        let file_path = "./tests/fixture.txt";
        let tmp_file_path = "./tests/tmp/fixture_tmp.txt";
        //copy file to tmp folder
        let mut file = File::open(file_path).unwrap();
        let mut contents = String::new();
        Read::read_to_string(&mut file, &mut contents).unwrap();
        let mut file = File::create(tmp_file_path).unwrap();
        file.write_all(contents.as_bytes()).unwrap();

        assert_eq!(
            replace_file(
                tmp_file_path.to_string(),
                10,
                r"'([^']+)'\s+\((\d{4})\)".to_string(),
                "spectre $2".to_string(),
            ),
            true
        );
        let mut file = std::fs::File::open(&tmp_file_path).unwrap();
        let mut contents = String::new();
        Read::read_to_string(&mut file, &mut contents).unwrap();
        let mut lines = contents.lines();
        let line = lines.nth(9).unwrap();
        assert_eq!(line, "Not my favorite movie: spectre 1943.");
    }
}
