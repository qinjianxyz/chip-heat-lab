use anyhow::{Context, Result};
use chip_heat_core::{schema_bundle, solve, ScenarioInput};
use clap::Parser;
use std::fs;
use std::io::{self, Read};
use std::path::PathBuf;

#[derive(Debug, Parser)]
#[command(name = "chip_heat_cli")]
#[command(about = "Solve the Chip Heat Lab simplified thermal demo scenario")]
struct Args {
    /// Read ScenarioInput JSON from this file. If omitted, stdin is used.
    #[arg(short, long)]
    input: Option<PathBuf>,

    /// Pretty-print JSON output.
    #[arg(long)]
    pretty: bool,

    /// Emit JSON schemas for ScenarioInput and SimulationResult.
    #[arg(long)]
    schema: bool,
}

fn main() -> Result<()> {
    let args = Args::parse();

    if args.schema {
        print_json(&schema_bundle(), args.pretty)?;
        return Ok(());
    }

    let input = read_input(args.input)?;
    let result = solve(&input);
    print_json(&result, args.pretty)?;
    Ok(())
}

fn read_input(path: Option<PathBuf>) -> Result<ScenarioInput> {
    let payload = if let Some(path) = path {
        fs::read_to_string(&path).with_context(|| format!("reading {}", path.display()))?
    } else {
        let mut buffer = String::new();
        io::stdin()
            .read_to_string(&mut buffer)
            .context("reading ScenarioInput JSON from stdin")?;
        buffer
    };

    if payload.trim().is_empty() {
        Ok(ScenarioInput::default())
    } else {
        serde_json::from_str(&payload).context("parsing ScenarioInput JSON")
    }
}

fn print_json<T: serde::Serialize>(value: &T, pretty: bool) -> Result<()> {
    if pretty {
        println!("{}", serde_json::to_string_pretty(value)?);
    } else {
        println!("{}", serde_json::to_string(value)?);
    }
    Ok(())
}
