use anyhow::{Context, Result};
use chip_heat_core::{
    schema_bundle, solve, solve_transient, ScenarioInput, TransientScenarioInput,
};
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

    /// Read TransientScenarioInput JSON and emit TransientSimulationResult JSON.
    #[arg(long)]
    transient: bool,
}

fn main() -> Result<()> {
    let args = Args::parse();

    if args.schema {
        print_json(&schema_bundle(), args.pretty)?;
        return Ok(());
    }

    let payload = read_payload(args.input)?;
    if args.transient {
        let input = parse_or_default::<TransientScenarioInput>(&payload)?;
        let result = solve_transient(&input);
        print_json(&result, args.pretty)?;
    } else {
        let input = parse_or_default::<ScenarioInput>(&payload)?;
        let result = solve(&input);
        print_json(&result, args.pretty)?;
    }
    Ok(())
}

fn read_payload(path: Option<PathBuf>) -> Result<String> {
    let payload = if let Some(path) = path {
        fs::read_to_string(&path).with_context(|| format!("reading {}", path.display()))?
    } else {
        let mut buffer = String::new();
        io::stdin()
            .read_to_string(&mut buffer)
            .context("reading ScenarioInput JSON from stdin")?;
        buffer
    };
    Ok(payload)
}

fn parse_or_default<T>(payload: &str) -> Result<T>
where
    T: Default + serde::de::DeserializeOwned,
{
    if payload.trim().is_empty() {
        Ok(T::default())
    } else {
        serde_json::from_str(payload).context("parsing input JSON")
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
