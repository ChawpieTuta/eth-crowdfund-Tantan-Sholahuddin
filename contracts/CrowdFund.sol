// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title CrowdFund - Decentralized Crowdfunding Platform
/// @author [Nama Anda]
/// @notice Platform crowdfunding terdesentralisasi di Ethereum
/// @dev Challenge Final Ethereum Co-Learning Camp

contract CrowdFund {
    // ============================================
    // ENUMS & STRUCTS
    // ============================================

    enum CampaignStatus {
        Active,
        Successful,
        Failed,
        Claimed
    }

    struct Campaign {
        uint256 campaignId;
        address creator;
        string title;
        string description;
        uint256 goalAmount;
        uint256 currentAmount;
        uint256 deadline;
        uint256 createdAt;
        CampaignStatus status;
        uint256 contributorCount;
    }

    // ============================================
    // STATE VARIABLES
    // ============================================

    // TODO: Deklarasikan state variables
    // Hint: campaignCounter, constants, mappings
    uint256 public campaignCounter;
    uint256 public constant MIN_GOAL = 0.01 ether;
    uint256 public constant MAX_DURATION = 90 days;
    uint256 public constant MIN_DURATION = 1 days;
    uint256 public constant MIN_CONTRIBUTION = 0.001 ether;

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    mapping(uint256 => mapping(address => bool)) public hasContributed;
    mapping(address => uint256[]) public creatorCampaigns;

    // ============================================
    // EVENTS
    // ============================================

    // TODO: Deklarasikan semua events
    event CampaignCreated(
        uint256 indexed campaignId, 
        address indexed creator, 
        string title, 
        uint256 goalAmount, 
        uint256 deadline
        );
    event ContributionMade(
        uint256 indexed campaignId, 
        address indexed contributor, 
        uint256 amount, 
        uint256 totalRaised
        );
    event CampaignSuccessful(
        uint256 indexed campaignId,
        uint256 totalRaised
        );
    event FundsClaimed(
        uint256 indexed campaignId, 
        address indexed creator, 
        uint256 amount
        );
    event RefundIssued(
        uint256 indexed campaignId, 
        address indexed contributor, 
        uint256 amount
        );
    event CampaignFailed(
        uint256 indexed campaignId, 
        uint256 totalRaised, 
        uint256 goalAmount
        );

    // ============================================
    // MODIFIERS
    // ============================================

    // TODO: Buat modifiers (campaignExists, onlyCreator, dll)
    modifier campaignExists(uint256 _campaignId) {
        require(campaigns[_campaignId].creator != address(0), "Campaign does not exist");
        _;
    }

    modifier onlyCreator(uint256 _campaignId) {
        require(campaigns[_campaignId].creator == msg.sender, "Only creator can perform this action");
        _;
    }

    modifier onlyContributor(uint256 _campaignId) {
        require(campaigns[_campaignId].creator != msg.sender, "Creator cannot contribute to their own campaign");
        _;
    }

    modifier isActive(uint256 _campaignId) {
        require(campaigns[_campaignId].creator != address(0), "Campaign does not exist");
        _;
    }

    // ============================================
    // MAIN FUNCTIONS
    // ============================================

    /// @notice Buat campaign crowdfunding baru
    /// @param _title Judul campaign
    /// @param _description Deskripsi campaign
    /// @param _goalAmount Target dana (dalam wei)
    /// @param _durationDays Durasi campaign dalam hari
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goalAmount,
        uint256 _durationDays
    ) public {
        // TODO: Implementasi
        // 1. Validasi goalAmount >= MIN_GOAL
        require(_goalAmount >= MIN_GOAL, "Goal amount is too low");
        // 2. Validasi durasi (MIN_DURATION <= duration <= MAX_DURATION)
        uint256 duration = _durationDays * 1 days;
        require(duration >= MIN_DURATION && duration <= MAX_DURATION, "Duration is invalid");
        // 3. Increment campaignCounter
        campaignCounter++;
        // 4. Hitung deadline = block.timestamp + (_durationDays * 1 days)
        uint256 deadline = block.timestamp + duration;
        // 5. Buat Campaign struct baru
        campaigns[campaignCounter] = Campaign({
            campaignId: campaignCounter,
            creator: msg.sender,
            title: _title,
            description: _description,
            goalAmount: _goalAmount,
            currentAmount: 0,
            deadline: deadline,
            createdAt: block.timestamp,
            status: CampaignStatus.Active,
            contributorCount: 0
        });
        // 6. Simpan di mapping
        creatorCampaigns[msg.sender].push(campaignCounter);
        // 7. Tambahkan campaignId ke creatorCampaigns
        // 8. Emit event
        emit CampaignCreated(
            campaignCounter, 
            msg.sender, 
            _title, 
            _goalAmount, 
            deadline
            );
    }

    /// @notice Kontribusi ETH ke campaign
    /// @param _campaignId ID campaign
    function contribute(uint256 _campaignId) 
    public payable 
    campaignExists(_campaignId)
    isActive(_campaignId)
    {
        // TODO: Implementasi
        Campaign storage campaign = campaigns[_campaignId];
        // 1. Validasi campaign masih Active
        require(campaign.status == CampaignStatus.Active, "Campaign is not active");
        // 2. Validasi belum lewat deadline
        require(block.timestamp < campaign.deadline, "Campaign deadline passed");
        // 3. Validasi msg.value >= MIN_CONTRIBUTION
        require(msg.value >= MIN_CONTRIBUTION, "Contribution too small");
        // 4. Validasi creator tidak bisa kontribusi ke campaign sendiri
        require(campaign.creator != msg.sender, "Creator cannot contribute");
        // 5. Update contributions mapping
        contributions[_campaignId][msg.sender] += msg.value;
        // 6. Update currentAmount
        campaign.currentAmount += msg.value;
        // 7. Track contributor unik (hasContributed)
        if(!hasContributed[_campaignId][msg.sender]) {
            hasContributed[_campaignId][msg.sender] = true;
            campaign.contributorCount++;
        }
        // 8. Jika currentAmount >= goalAmount, update status ke Successful
        if(campaign.currentAmount >= campaign.goalAmount) {
            campaign.status = CampaignStatus.Successful;
            emit CampaignSuccessful(_campaignId, campaign.currentAmount);
        }
        // 9. Emit event
        emit ContributionMade(_campaignId, msg.sender, msg.value, campaign.currentAmount);
    }

    /// @notice Creator claim dana setelah campaign sukses
    /// @param _campaignId ID campaign
    function claimFunds(uint256 _campaignId) 
    public 
        // 1. Validasi caller adalah creator
    campaignExists(_campaignId)
    onlyCreator(_campaignId) 
    {
        // TODO: Implementasi
        Campaign storage campaign = campaigns[_campaignId];
        // 2. Validasi status = Successful
        require(campaign.status == CampaignStatus.Successful, "Campaign not successful");
        // 3. Update status ke Claimed
        campaign.status = CampaignStatus.Claimed;
        // 4. Transfer dana ke creator
        uint256 amount = campaign.currentAmount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        // 5. Emit event
        emit FundsClaimed(_campaignId, msg.sender, amount);
    }

    /// @notice Kontributor refund jika campaign gagal
    /// @param _campaignId ID campaign
    function refund(uint256 _campaignId) 
    public
    campaignExists(_campaignId)
    onlyContributor(_campaignId) 
    {
        // TODO: Implementasi
        Campaign storage campaign = campaigns[_campaignId];
        // 1. Validasi status = Failed
        require(campaign.status == CampaignStatus.Failed, "Campaign not failed");
        // 2. Validasi caller punya kontribusi > 0
        uint256 amount = contributions[_campaignId][msg.sender];
        contributions[_campaignId][msg.sender] = 0;
        // 3. Simpan amount, set kontribusi ke 0 (prevent reentrancy)
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        // 4. Transfer refund ke caller
        require(success, "Refund failed");
        // 5. Emit event
        emit RefundIssued(_campaignId, msg.sender, amount);
    }

    /// @notice Cek dan update status campaign
    /// @param _campaignId ID campaign
    function checkCampaign(uint256 _campaignId) public campaignExists(_campaignId) {
        // TODO: Implementasi
        Campaign storage campaign = campaigns[_campaignId];
        if (campaign.status != CampaignStatus.Active) return;
        if (block.timestamp < campaign.deadline) return;
    
        // Jika deadline lewat dan status masih Active:
        if (campaign.currentAmount >= campaign.goalAmount) {
        //   - Jika currentAmount >= goalAmount → Successful
            campaign.status = CampaignStatus.Successful;
            emit CampaignSuccessful(_campaignId, campaign.currentAmount);
        } else {
        //   - Jika currentAmount < goalAmount → Failed
            campaign.status = CampaignStatus.Failed;
            emit CampaignFailed(_campaignId, campaign.currentAmount, campaign.goalAmount);
        }
    }

    // ============================================
    // VIEW FUNCTIONS
    // ============================================

    /// @notice Lihat detail campaign
    function getCampaignDetails(uint256 _campaignId) 
        // Jika campaign tidak ditemukan, gunakan require() untuk revert
    public view campaignExists(_campaignId) 
    returns (Campaign memory) 
    {
        // TODO: Implementasi
        return campaigns[_campaignId];
    }

    /// @notice Lihat kontribusi saya di campaign
    function getMyContribution(uint256 _campaignId) public view returns (uint256) {
        // TODO: Implementasi
        return contributions[_campaignId][msg.sender];
    }

    /// @notice Lihat semua campaign yang saya buat
    function getMyCampaigns() public view returns (uint256[] memory) {
        // TODO: Implementasi
        return creatorCampaigns[msg.sender];
    }

    /// @notice Lihat sisa waktu campaign
    function getTimeRemaining(uint256 _campaignId) 
    public view campaignExists(_campaignId) 
    returns (uint256) 
    {
        // TODO: Implementasi
        // Jika deadline sudah lewat, return 0
        if (block.timestamp >= campaigns[_campaignId].deadline) return 0;
        // Jika belum, return deadline - block.timestamp
        return campaigns[_campaignId].deadline - block.timestamp;
    }

    /// @notice Lihat saldo contract
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}