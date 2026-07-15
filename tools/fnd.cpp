/*
 * SPDX-FileCopyrightText: Majaahh
 * SPDX-License-Identifier: Apache-2.0
 */

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <filesystem>
#include <fnmatch.h>
#include <iostream>
#include <string>
#include <vector>

namespace fs = std::filesystem;

namespace {

std::string to_lower(const std::string &str) {
  std::string result = str;
  std::transform(result.begin(), result.end(), result.begin(),
                 [](unsigned char c) { return std::tolower(c); });
  return result;
}

std::string trim_leading(const std::string &path) {
  if (path.size() >= 2 && path[0] == '.' && path[1] == '/') {
    return path.substr(2);
  }
  return path;
}

enum class EntryType { Any, File, Dir, Symlink };

struct Options {
  std::string pattern;
  std::vector<std::string> search_paths;
  bool only_exact_match = false;
  bool case_sensitive = false;
  bool follow_symlinks = false;
  bool print_full_path = false;
  int max_depth = -1; // -1 = unlimited
  EntryType type = EntryType::Any;
};

void print_usage(const char *prog) {
  std::cout
      << "Usage: " << prog << " <name> [path...] [options]\n"
      << "Search for files matching a pattern or exact name.\n\n"
      << "Args:\n"
      << "  <name>                Required name or pattern to search for\n"
      << "  [path...]             Optional paths to search in (default: .)\n\n"
      << "Options:\n"
      << "  -o, --only            Match only exact name (glob via fnmatch)\n"
      << "  -c, --case-sensitive  Case-sensitive matching (default: "
         "case-insensitive)\n"
      << "  -L, --follow-symlinks Follow symlinked directories while walking\n"
      << "  -d, --max-depth N     Limit recursion depth (default: unlimited)\n"
      << "  -t, --type TYPE       Restrict to type: f (file), d (dir), l "
         "(symlink)\n"
      << "  -f, --full-path       Print absolute paths instead of relative\n"
      << "  -h, --help            Show this help message\n";
}

bool matches_type(const fs::directory_entry &entry, EntryType type) {
  std::error_code ec;
  switch (type) {
  case EntryType::Any:
    return true;
  case EntryType::File:
    return entry.is_regular_file(ec) && !ec;
  case EntryType::Dir:
    return entry.is_directory(ec) && !ec;
  case EntryType::Symlink:
    return entry.is_symlink(ec) && !ec;
  }
  return false;
}

bool name_matches(const std::string &filename, const std::string &full_trimmed,
                  const Options &opts) {
  if (opts.only_exact_match) {
    int flags = opts.case_sensitive ? 0 : FNM_CASEFOLD;
    return fnmatch(opts.pattern.c_str(), filename.c_str(), flags) == 0;
  }

  if (opts.case_sensitive) {
    return full_trimmed.find(opts.pattern) != std::string::npos;
  }
  return to_lower(full_trimmed).find(to_lower(opts.pattern)) !=
         std::string::npos;
}

void walk_directory(const fs::path &root_path, const Options &opts) {
  std::error_code ec;

  auto fs_options = fs::directory_options::skip_permission_denied;
  if (opts.follow_symlinks) {
    fs_options |= fs::directory_options::follow_directory_symlink;
  }

  fs::recursive_directory_iterator it(root_path, fs_options, ec);
  fs::recursive_directory_iterator end;

  if (ec) {
    std::cerr << "E: Cannot open directory " << root_path << ": "
              << ec.message() << '\n';
    return;
  }

  for (; it != end;) {
    if (opts.max_depth >= 0 && it.depth() > opts.max_depth) {
      it.disable_recursion_pending();
    }

    const fs::directory_entry &entry = *it;

    if (!matches_type(entry, opts.type)) {
      it.increment(ec);
      if (ec) {
        std::cerr << "E: " << ec.message() << '\n';
        ec.clear();
      }
      continue;
    }

    std::string full_path = entry.path().string();
    std::string trimmed = trim_leading(full_path);
    std::string filename = entry.path().filename().string();

    if (name_matches(filename, trimmed, opts)) {
      if (opts.print_full_path) {
        std::cout << fs::absolute(entry.path(), ec).string() << '\n';
      } else {
        std::cout << trimmed << '\n';
      }
    }

    it.increment(ec);
    if (ec) {
      // Skip whatever caused the error (e.g. race/removal, denied) and
      // keep walking rather than aborting the whole search.
      std::cerr << "E: " << ec.message() << '\n';
      ec.clear();
    }
  }
}

bool parse_type(const std::string &s, EntryType &out) {
  if (s == "f") {
    out = EntryType::File;
  } else if (s == "d") {
    out = EntryType::Dir;
  } else if (s == "l") {
    out = EntryType::Symlink;
  } else {
    return false;
  }
  return true;
}

} // namespace

int main(int argc, char *argv[]) {
  if (argc < 2) {
    print_usage(argv[0]);
    return 1;
  }

  Options opts;
  std::vector<std::string> positional;

  for (int i = 1; i < argc; i++) {
    std::string arg = argv[i];

    if (arg == "-h" || arg == "--help") {
      print_usage(argv[0]);
      return 0;
    } else if (arg == "-o" || arg == "--only") {
      opts.only_exact_match = true;
    } else if (arg == "-c" || arg == "--case-sensitive") {
      opts.case_sensitive = true;
    } else if (arg == "-L" || arg == "--follow-symlinks") {
      opts.follow_symlinks = true;
    } else if (arg == "-f" || arg == "--full-path") {
      opts.print_full_path = true;
    } else if (arg == "-d" || arg == "--max-depth") {
      if (i + 1 >= argc) {
        std::cerr << "E: " << arg << " requires a value\n";
        return 1;
      }
      try {
        opts.max_depth = std::stoi(argv[++i]);
      } catch (const std::exception &) {
        std::cerr << "E: Invalid depth value: " << argv[i] << '\n';
        return 1;
      }
    } else if (arg == "-t" || arg == "--type") {
      if (i + 1 >= argc || !parse_type(argv[++i], opts.type)) {
        std::cerr << "E: --type requires one of: f, d, l\n";
        return 1;
      }
    } else if (!arg.empty() && arg[0] == '-' && arg != "-") {
      std::cerr << "E: Unknown option: " << arg << '\n';
      return 1;
    } else {
      positional.push_back(arg);
    }
  }

  if (positional.empty()) {
    std::cerr << "E: Missing required <filename> pattern\n";
    print_usage(argv[0]);
    return 1;
  }

  opts.pattern = positional.front();
  opts.search_paths.assign(positional.begin() + 1, positional.end());
  if (opts.search_paths.empty()) {
    opts.search_paths.push_back(".");
  }

  bool any_valid = false;
  for (const auto &p : opts.search_paths) {
    std::error_code ec;
    if (!fs::is_directory(p, ec) || ec) {
      std::cerr << "E: Path not found or not a directory: " << p << '\n';
      continue;
    }
    any_valid = true;
    walk_directory(p, opts);
  }

  return any_valid ? 0 : 1;
}
