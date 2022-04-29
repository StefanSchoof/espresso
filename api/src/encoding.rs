use funksteckdose::{error::Error, Device, Encoding, State};

pub struct MyEncoding;

impl Encoding for MyEncoding {
    fn encode(group: &str, device: &Device, state: &State) -> Result<Vec<u8>, Error> {
        if group.len() != 5 || group.chars().any(|c| c != '0' && c != '1') {
            return Err(Error::InvalidGroup(group.into()));
        }
        let chars = group.chars();

        let device = match device {
            Device::A => "11110",
            _ => unimplemented!(),
        };

        let chars = chars.chain(device.chars());

        let chars = match *state {
            State::On => chars.chain("00".chars()),
            State::Off => chars.chain("01".chars()),
        };

        Ok(chars
            .map(|c| match c {
                '0' => b'F',
                _ => b'0',
            })
            .collect())
    }
}
