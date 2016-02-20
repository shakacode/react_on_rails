require 'rspectacular'
require 'ruby-progressbar/format/molecule'

class     ProgressBar
module    Format
describe  Molecule do
  it 'sets the key when initialized' do
    molecule = Molecule.new('t')

    expect(molecule.key).to eql 't'
  end

  it 'sets the method name when initialized' do
    molecule = Molecule.new('t')

    expect(molecule.method_name).to eql [:title_comp, :title]
  end

  it 'can retrieve the full key for itself' do
    molecule = Molecule.new('t')

    expect(molecule.full_key).to eql '%t'
  end

  it 'can determine if it is a bar molecule' do
    expect(Molecule.new('B')).to be_bar_molecule
  end
end
end
end
