::EMPLOYEE_ADMINS = YAML.load <<-EOM
- name: Adam Jacob
  opscode_alias: adamhjk
  rubygems_username: 43081
  rubygems_email:    adam@opscode.com
- name: Adam Edwards
  rubygems_username: adamedx
  rubygems_email:    adamedx@gmail.com
- name: Bryan McLellan
  rubygems_username: btm
  rubygems_email:    btm@loftninjas.org
- name: Chris Doherty
  rubygems_username: randomcamel
  rubygems_email:    code@randomcamel.net
- name: Claire McQuin
  rubygems_username: mcquin
  rubygems_email:    claire@chef.io
- name: Daniel DeLeo
  rubygems_username: danielsdeleo
  rubygems_email:    danielsdeleo@mac.com
- name: Eric Bixler
  rubygems_username: fishbix
  rubygems_email:    eric@opscode.com
- name: Fletcher Nichol
  rubygems_username: fnichol
  rubygems_email:    fnichol@nichol.ca
- name: George Miranda
  github_username:   gmiranda23
  rubygems_username: gmiranda23
  rubygems_email:    gmiranda@chef.io
- name: Jay Mundrawala
  rubygems_username: jdmundrawala
  rubygems_email:    jdmundrawala@gmail.com
- name: JJ Asghar
  rubygems_username: jjasghar
  rubygems_email:    jjasghar@gmail.com
- name: John Keiser
  rubygems_username: jkeiser
  rubygems_email:    john@johnkeiser.com
- name: Joshua Timberman
  rubygems_username: jtimberman
  rubygems_email:    joshua@opscode.com
- name: Kartik Subrama
  rubygems_username: ksubramanian
  rubygems_email:    ksubramanian@chef.io
- name: Lamont Granquist
  rubygems_username: lamont-granquist
  rubygems_email:    lamont@scriptkiddie.org
- name: Mark Anderson
  rubygems_username: manderson26
  rubygems_email:    mark@opscode.com
- name: Matt Ray
  rubygems_username: mattray
  rubygems_email:    matthewhray@gmail.com
- name: Matt Wrock
  rubygems_username: mwrockx
  rubygems_email:    matt@mattwrock.com
- name: Nathan Smith
  rubygems_username: nlsmith
  rubygems_email:    nlloyds@gmail.com
- name: Salim Alam
  rubygems_username: chefsalim
  rubygems_email:    salam@chef.io
- name: Serdar Sutay
  rubygems_username: sersut
  rubygems_email:    serdar@opscode.com
- name: Seth Chisamore
  rubygems_username: schisamo
  rubygems_email:    schisamo@chef.io
- name: Seth Falcon
  rubygems_username: sfalcon
  rubygems_email:    seth@opscode.com
- name: Seth Thomas
  rubygems_username: cheeseplus
  rubygems_email:    sthomas@chef.io
- name: Steven Danna
  rubygems_username: sdanna
  rubygems_email:    steve@opscode.com
- name: Tyler Ball
  rubygems_username: tyleraball
  rubygems_email:    tyleraball@gmail.com
- name: Yvonne Lam
  rubygems_username: yzl
  rubygems_email:    yvonne.z.lam@gmail.com
EOM

::EMPLOYEES = ::EMPLOYEE_ADMINS + YAML.load(<<-EOM)
- name: Grant Hudgens
  rubygems_username: ghudgens
  rubygems_email:    grant.hudgens@gmail.com
  rubygems:
  - knife-ec-backup
- name: Jeremiah Snapp
  rubygems_username: snapp
  rubygems_email:    jeremiah.snapp@gmail.com
  rubygems:
  - knife-acl
- name: Ryan Cragun
  rubygems_username: ryancragun
  rubygems_email:    me@ryan.ec
  rubygems:
  - knife-ec-backup
- name: Sean Horn
  rubygems_username: sean_horn
  rubygems_email:    sean_horn@opscode.com
  rubygems:
  - knife-acl
EOM

::EMPLOYEE_ADMINS.each do |employee|
  employee['groups'] ||= []
  employee['groups'] << 'chef-admins'
end

::EMPLOYEES.each do |employee|
  employee['groups'] ||= []
  employee['groups'] << 'chef-employees'
end

::NON_EMPLOYEES = YAML.load <<-EOM
- name: Jesse Adams
  rubygems_username: technogeek
  rubygems_email:    jesse@techno-geeks.org
  rubygems:
  - knife-linode
- name: Stuart Preston
  rubygems_username: stuartpreston
  rubygems_email:    stuart@pendrica.com
  rubygems:
  - chef-provisioning-azure
- name: Seth Vargo
  rubygems_username: sethvargo
  rubygems_email:    sethvargo@gmail.com
  rubygems:
  - test-kitchen
  - dep_selector
EOM

::PEOPLE = ::EMPLOYEES + ::NON_EMPLOYEES
