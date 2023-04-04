use std::{collections::HashMap, fs, path::Path};

use clap::Parser;
use envfile::EnvFile;
use serde::{Deserialize, Serialize};

#[derive(Parser, Default, Debug)]
struct Arguments {
    config_path: String,
    out_dir: String,
}

#[derive(Debug, PartialEq, Serialize, Deserialize)]
struct Machine {
    name: String,
    envs: Vec<String>,
    config: String,
}

#[derive(Debug, PartialEq, Serialize, Deserialize)]
struct Config {
    machines: Vec<Machine>,
}

fn main() {
    let args = Arguments::parse();

    let config = match fs::read_to_string(args.config_path) {
        Ok(config) => config,
        Err(e) => panic!("Error reading config file: {}", e),
    };

    let machines_config: Config = match serde_yaml::from_str(&config) {
        Ok(machines) => machines,
        Err(e) => panic!("Error parsing config file: {}", e),
    };

    for machine in machines_config.machines {
        let mut variables: HashMap<String, String> = HashMap::new();

        machine.envs.iter().for_each(|env| {
            let env_file = match EnvFile::new(&Path::new(env)) {
                Ok(env_file) => env_file,
                Err(e) => panic!("Error reading env file: {}", e),
            };

            for (key, value) in &env_file.store {
                variables.insert(key.to_string(), value.to_string());
            }
        });

        let machine_config = match fs::read_to_string(machine.config) {
            Ok(config) => config,
            Err(e) => panic!("Error reading config file: {}", e),
        };

        let output = match subst::substitute(&machine_config, &variables) {
            Ok(output) => output,
            Err(e) => panic!("Error substituting config file: {}", e),
        };

        fs::write(format!("{}/{}.bu", args.out_dir, machine.name), output)
            .expect("Unable to write file");
    }
}
